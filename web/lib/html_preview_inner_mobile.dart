import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildHtmlPreviewImpl(String htmlSource) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(htmlSource);
  return WebViewWidget(controller: controller);
}
