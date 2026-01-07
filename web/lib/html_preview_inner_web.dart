// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:ui_web' as ui;

import 'package:flutter/widgets.dart';

Widget buildHtmlPreviewImpl(String htmlSource) {
  final viewType = 'html-preview-${DateTime.now().microsecondsSinceEpoch}';

  ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..style.border = 'none'
      ..srcdoc = htmlSource;
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}
