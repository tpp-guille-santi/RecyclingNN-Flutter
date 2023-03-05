import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  final CameraController? controller;
  final Future<void>? future;

  CameraScreen({required this.future, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final scale = 1 /
              (controller!.value.aspectRatio *
                  MediaQuery.of(context).size.aspectRatio);
          return Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: CameraPreview(controller!),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
