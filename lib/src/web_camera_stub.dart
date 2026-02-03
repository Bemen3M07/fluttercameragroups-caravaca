import 'package:flutter/material.dart';

class WebCameraWidget extends StatefulWidget {
  WebCameraWidget({Key? key}) : super(key: key);

  @override
  WebCameraWidgetState createState() => WebCameraWidgetState();
}

class WebCameraWidgetState extends State<WebCameraWidget> {
  Future<String?> capture({bool triggerDownload = true}) async => null;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Web camera not available on this platform.'));
  }
}
