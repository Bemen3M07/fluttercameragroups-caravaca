// Web implementation using getUserMedia and HtmlElementView
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

class WebCameraWidget extends StatefulWidget {
  WebCameraWidget({Key? key}) : super(key: key);

  @override
  WebCameraWidgetState createState() => WebCameraWidgetState();
}

class WebCameraWidgetState extends State<WebCameraWidget> {
  late html.VideoElement _video;
  late final String _viewId;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _video = html.VideoElement();
    _video.autoplay = true;
    _video.playsInline = true;
    _viewId = 'webcam-${_video.hashCode}';

    // Register the view factory for the HtmlElementView
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => _video);

    _start();
  }

  Future<void> _start() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({'video': true});
      _video.srcObject = stream;
      await _video.play();
      setState(() {
        _started = true;
      });
    } catch (e) {
      // ignore and leave _started false
      debugPrint('Web camera start error: $e');
    }
  }

  /// Captures a frame from the video and returns a data URL (jpeg).
  /// If [triggerDownload] is true, the browser will prompt to download the image.
  Future<String?> capture({bool triggerDownload = true}) async {
    if (!_started || _video.videoWidth == 0 || _video.videoHeight == 0) return null;
    final canvas = html.CanvasElement(width: _video.videoWidth, height: _video.videoHeight);
    final ctx = canvas.context2D;
    ctx.drawImage(_video, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);

    if (triggerDownload) {
      final anchor = html.AnchorElement(href: dataUrl)..download = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
    }

    return dataUrl;
  }

  @override
  void dispose() {
    try {
      final stream = _video.srcObject as html.MediaStream?;
      stream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
