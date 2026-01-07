import 'package:flutter/widgets.dart';

import 'html_preview_inner_stub.dart'
    if (dart.library.html) 'html_preview_inner_web.dart'
    if (dart.library.io) 'html_preview_inner_mobile.dart';

class HtmlPreviewInner extends StatelessWidget {
  const HtmlPreviewInner({super.key, required this.htmlSource});

  final String htmlSource;

  @override
  Widget build(BuildContext context) {
    return buildHtmlPreviewImpl(htmlSource);
  }
}
