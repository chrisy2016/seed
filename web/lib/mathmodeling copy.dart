import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'html_preview_inner.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;

class MathModelingPage extends StatefulWidget {
  const MathModelingPage({super.key});

  @override
  State<MathModelingPage> createState() => _MathModelingPageState();
}

class _MathModelingPageState extends State<MathModelingPage> {
  late final BackendLlmProvider _provider;
  String? _htmlPreviewSource;

  void _showHtmlPreview(String html) {
    setState(() {
      _htmlPreviewSource = html;
    });
  }

  void _closeHtmlPreview() {
    setState(() {
      _htmlPreviewSource = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _provider = BackendLlmProvider();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数学建模'),
        actions: [
          IconButton(
            tooltip: '清空对话',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _provider.history = [];
            },
          ),
        ],
      ),
      body: Container(
        // 与全局 theme 一致：略微高于 scaffold 的深色
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  // 控制聊天区域最大宽度，居中显示
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Theme(
                    // 只在聊天区域内自定义文字选中高亮颜色
                    data: theme.copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        // 半透明主色，用于选中背景，在深色气泡上更清晰
                        selectionColor:
                            theme.colorScheme.primary.withOpacity(0.35),
                        selectionHandleColor: theme.colorScheme.primary,
                      ),
                    ),
                    child: LlmChatView(
                      provider: _provider,
                      style: _darkChatStyle(theme),
                      responseBuilder: _buildLlmResponse,
                      welcomeMessage: '你好，我是数学建模助手，可以帮你搭建和分析数学模型。',
                      suggestions: const [
                        '帮我建立一个线性回归模型',
                        '如何用数学模型描述人口增长？',
                        '帮我分析这个最优化问题的建模思路',
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_htmlPreviewSource != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _HtmlPreviewPanel(
                  htmlSource: _htmlPreviewSource!,
                  theme: theme,
                  onClose: _closeHtmlPreview,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 自定义 LLM 回复内容：在回复内容下方增加一个复制按钮。
  Widget _buildLlmResponse(BuildContext context, String response) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Markdown 正文
        MarkdownBody(
          data: response,
          inlineSyntaxes: [InlineLatexSyntax(), InlineParenLatexSyntax()],
          blockSyntaxes: [BlockLatexSyntax()],
          styleSheet: MarkdownStyleSheet(
            p: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            listBullet:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            code: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 14,
              backgroundColor: Colors.transparent,
            ),
          ),
          // 自定义代码块渲染：整行展示，并在上方增加操作卡
          // 仅对 ``` 包围的代码块生效，行内 `code` 不受影响
          builders: {
            'code': CodeBlockBuilder(theme, onRunHtml: _showHtmlPreview),
            'inline_latex': LatexElementBuilder(isBlock: false),
            'block_latex': LatexElementBuilder(isBlock: true),
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: const Size(0, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('复制', style: TextStyle(fontSize: 12)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: response));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制该条回复')),
              );
            },
          ),
        ),
      ],
    );
  }
}

LlmChatViewStyle _darkChatStyle(ThemeData theme) {
  final scheme = theme.colorScheme;

  return LlmChatViewStyle(
    // 背景使用与 main.dart 一致的深色表面
    backgroundColor: scheme.surface,
    progressIndicatorColor: scheme.secondary,
    suggestionStyle: SuggestionStyle(
      // 建议文字使用纯白，保证在深灰卡片上清晰可见
      textStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
    ),
    chatInputStyle: ChatInputStyle(
      // 输入框为深灰，接近卡片色
      backgroundColor: const Color(0xFF2A2A35),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      // 输入文字为纯白
      textStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
      hintText: '请输入你的数学问题...',
      // 提示文字略浅灰
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
    ),
    userMessageStyle: UserMessageStyle(
      textStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
      decoration: BoxDecoration(
        // 用户气泡使用全局 primary 色（0xFF6C63FF）
        color: scheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    llmMessageStyle: LlmMessageStyle(
      // 放大 AI 消息气泡的宽度，使其与聊天区域一致
      maxWidth: 900,
      minWidth: 900,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        // 机器人气泡略深于 surface，接近卡片色
        color: const Color(0xFF2A2A35),
        borderRadius: BorderRadius.circular(18),
      ),
      // 通过 markdownStyle 强制 LLM 文本为白色
      markdownStyle: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
        listBullet: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
        // 代码文字也去掉自带的黑色背景，改为透明，方便选中高亮
        code: const TextStyle(
          color: Colors.white,
          backgroundColor: Colors.transparent,
        ),
      ),
    ),
  );
}

/// 使用后端 http://127.0.0.1:8000/chat/stream 的自定义 Provider。
///
/// 后端返回的是 SSE 流：每一行形如 "data: 内容"，由 FastAPI 的
/// StreamingResponse(event_generator, media_type="text/event-stream") 提供。
class BackendLlmProvider extends LlmProvider {
  BackendLlmProvider() : _client = http.Client();

  static const String _apiUrl = 'http://127.0.0.1:8000/chat/stream';

  final http.Client _client;
  final List<ChatMessage> _history = <ChatMessage>[];

  // 手动管理 Listenable 监听器
  final List<VoidCallback> _listeners = <VoidCallback>[];

  @override
  List<ChatMessage> get history => List.unmodifiable(_history);

  @override
  set history(Iterable<ChatMessage> value) {
    _history
      ..clear()
      ..addAll(value);
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 兼容非流式调用：内部还是走流式接口，把所有片段拼接成一个字符串。
  @override
  Future<String> generate(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in generateStream(
      prompt,
      attachments: attachments,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  /// 流式输出：对接 FastAPI 的 /chat/stream SSE 接口。
  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    final uri = Uri.parse(_apiUrl);

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(<String, dynamic>{'prompt': prompt});

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      yield '网络错误：$e';
      return;
    }

    if (response.statusCode != 200) {
      yield '服务异常：HTTP ${response.statusCode}';
      return;
    }

    // 直接按文本流读取，不再用 LineSplitter 把换行拆掉，
    // 从而完整保留后端返回中的 "\n"、空行和代码块结构。
    final decoded = response.stream.transform(utf8.decoder);

    try {
      await for (final chunk in decoded) {
        if (chunk.isEmpty) {
          continue;
        }

        // 不做 trimLeft/trimRight，原样透传，换行也一并保留。
        yield chunk;
      }
    } catch (e) {
      yield '解析流数据出错：$e';
      return;
    }
  }

  /// LlmChatView 调用的主入口：发送一条消息并以字符串流式返回回复。
  ///
  /// 签名需要与抽象类 LlmProvider 中保持一致：
  ///   Stream<String> sendMessageStream(String prompt, { ... })
  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    // 先把用户消息加入历史并通知界面刷新。
    final userMessage = ChatMessage.user(prompt, attachments);
    _history.add(userMessage);
    _notifyListeners();

    if (prompt.isEmpty) {
      return;
    }

    // 创建一条空的 LLM 消息，后续通过 append 增量拼接内容。
    final llmMessage = ChatMessage.llm();
    _history.add(llmMessage);
    _notifyListeners();

    await for (final chunk in generateStream(
      prompt,
      attachments: attachments,
    )) {
      // 追加增量内容到同一条消息，实现气泡内文本逐步增长。
      llmMessage.append(chunk);
      _notifyListeners();

      // 对外按照约定返回增量字符串流。
      yield chunk;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// 解析 $inline$ 和 $$block$$ LaTeX 语法并交给 flutter_math_fork 渲染。
class InlineLatexSyntax extends md.InlineSyntax {
  InlineLatexSyntax() : super(r'\$(?!\$)(.+?)(?<!\$)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1);
    if (content == null) return false;
    parser.addNode(md.Element.text('inline_latex', content));
    return true;
  }
}

/// 解析 \( ... \) 形式的行内公式。
class InlineParenLatexSyntax extends md.InlineSyntax {
  InlineParenLatexSyntax() : super(r'\\\((.+?)\\\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1);
    if (content == null) return false;
    parser.addNode(md.Element.text('inline_latex', content));
    return true;
  }
}

class BlockLatexSyntax extends md.BlockSyntax {
  BlockLatexSyntax();

  @override
  RegExp get pattern => _startLine;

  static final RegExp _startLine = RegExp(r'^\s*(\$\$|\\\[)\s*$');
  static final RegExp _endDollar = RegExp(r'^\s*\$\$\s*$');
  static final RegExp _endBracket = RegExp(r'^\s*\\\]\s*$');
  static final RegExp _singleDollar = RegExp(r'^\s*\$\$(.+)\$\$\s*$');
  static final RegExp _singleBracket = RegExp(r'^\s*\\\[(.+)\\\]\s*$');

  @override
  bool canParse(md.BlockParser parser) {
    final line = parser.current.content;
    return _startLine.hasMatch(line) ||
        _singleDollar.hasMatch(line) ||
        _singleBracket.hasMatch(line);
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final line = parser.current.content;
    parser.advance();

    final singleDollar = _singleDollar.firstMatch(line);
    if (singleDollar != null) {
      return md.Element.text('block_latex', singleDollar.group(1)!.trim());
    }

    final singleBracket = _singleBracket.firstMatch(line);
    if (singleBracket != null) {
      return md.Element.text('block_latex', singleBracket.group(1)!.trim());
    }

    final bool isBracket = line.contains('\\[');
    final endPattern = isBracket ? _endBracket : _endDollar;

    final buffer = StringBuffer();
    while (!parser.isDone && !endPattern.hasMatch(parser.current.content)) {
      buffer.writeln(parser.current.content);
      parser.advance();
    }
    if (!parser.isDone) {
      parser.advance(); // 跳过结尾行
    }

    return md.Element.text('block_latex', buffer.toString().trim());
  }
}

class LatexElementBuilder extends MarkdownElementBuilder {
  LatexElementBuilder({required this.isBlock});

  final bool isBlock;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final mathSource = element.textContent.trim();
    if (mathSource.isEmpty) return null;

    final textStyle = (preferredStyle ?? const TextStyle()).copyWith(
      color: Colors.white,
    );

    final mathWidget = Math.tex(
      mathSource,
      textStyle: textStyle,
      onErrorFallback: (FlutterMathException e) => Text(
        mathSource,
        style: textStyle.copyWith(color: Colors.redAccent),
      ),
    );

    if (isBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: mathWidget,
      );
    }

    return mathWidget;
  }
}

/// Markdown 代码块自定义渲染：整行展示，并在上方增加一个操作卡。
class CodeBlockBuilder extends MarkdownElementBuilder {
  CodeBlockBuilder(this.theme, {this.onRunHtml});

  final ThemeData theme;
  final void Function(String html)? onRunHtml;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // flutter_markdown_plus 在解析 ``` 代码块时，会生成 <pre><code>...</code></pre>
    // 这里注册的是 'code' 的 builder，因此 element.tag 通常是 'code'
    // 为了避免影响行内 `code`，仅对包含换行符的多行代码使用自定义渲染
    if (element.tag != 'code') {
      return null;
    }

    // 取出代码块的纯文本内容
    final codeText = element.textContent;

    // 带语言标记的 ```python 这类 fenced code 也视为代码块
    final langClass = element.attributes['class'] ?? '';
    final isLanguageBlock = langClass.startsWith('language-');
    final isHtmlBlock =
        isLanguageBlock && langClass.toLowerCase().contains('language-html');

    // 单行 code 且不是 fenced block 的情况，仍然走默认渲染（行内 `code`）
    if (!isLanguageBlock && !codeText.contains('\n')) {
      return null;
    }

    final textStyle = (preferredStyle ?? const TextStyle()).copyWith(
      fontFamily: 'monospace',
      fontSize: 14,
      color: Colors.white,
      backgroundColor: Colors.transparent,
    );

    return _CodeBlockWithPreview(
      theme: theme,
      codeText: codeText,
      isHtmlBlock: isHtmlBlock,
      textStyle: textStyle,
      onRunHtml: onRunHtml,
    );
  }
}

class _CodeBlockWithPreview extends StatefulWidget {
  const _CodeBlockWithPreview({
    required this.theme,
    required this.codeText,
    required this.isHtmlBlock,
    required this.textStyle,
    this.onRunHtml,
  });

  final ThemeData theme;
  final String codeText;
  final bool isHtmlBlock;
  final TextStyle textStyle;
  final void Function(String html)? onRunHtml;

  @override
  State<_CodeBlockWithPreview> createState() => _CodeBlockWithPreviewState();
}

class _CodeBlockWithPreviewState extends State<_CodeBlockWithPreview> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final codePanel = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部操作卡
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF374151),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '代码块',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Row(
                  children: [
                    if (widget.isHtmlBlock && widget.onRunHtml != null)
                      IconButton(
                        tooltip: '运行 HTML',
                        icon: const Icon(Icons.play_arrow,
                            size: 16, color: Colors.white70),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => widget.onRunHtml!(widget.codeText),
                      ),
                    IconButton(
                      tooltip: '复制代码',
                      icon: const Icon(Icons.copy,
                          size: 16, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.codeText),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 代码块本体：在当前消息气泡内占满一行，支持横向滚动
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 0),
                child: Text(widget.codeText, style: widget.textStyle),
              ),
            ),
          ),
        ],
      ),
    );

    return codePanel;
  }
}

class _HtmlPreviewPanel extends StatelessWidget {
  const _HtmlPreviewPanel({
    required this.htmlSource,
    required this.theme,
    required this.onClose,
  });

  final String htmlSource;
  final ThemeData theme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '运行结果',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              IconButton(
                tooltip: '关闭预览',
                icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: HtmlPreviewInner(htmlSource: htmlSource),
            ),
          ),
        ],
      ),
    );
  }
}
