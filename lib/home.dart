import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision_raw_bytes/firebase_ml_vision_raw_bytes.dart';
import 'util_scanner.dart';

class home extends StatefulWidget {
  const home({Key? key}) : super(key: key);

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  bool isworking = false;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  Size? size;
  List<Face>? facelist;
  CameraDescription? description;
  CameraLensDirection cameraDirection = CameraLensDirection.front;
  initCamera() async {
    description = await utilsScanner.getCamera(cameraDirection);
    cameraController = CameraController(description!, ResolutionPreset.medium);
    faceDetector =
        FirebaseVision.instance.faceDetector(const FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
      mode: FaceDetectorMode.fast,
    ));
    await cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      cameraController!.startImageStream((imageFromStram) => {
            if (!isworking)
              {
                isworking = true,
                performDetectionOnStreamFrames(imageFromStram),
              }
          });
    });
  }

  dynamic scanResults;
  performDetectionOnStreamFrames(CameraImage cameraImage) async {
    utilsScanner
        .detect(
      image: cameraImage,
      detectInImage: faceDetector!.processImage,
      imageRotation: description!.sensorOrientation,
    )
        .then((dynamic results) {
      setState(() {
        scanResults = results;
      });
    }).whenComplete(() {
      isworking = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController?.dispose();
    faceDetector!.close();
  }

  Widget buildResult() {
    if (scanResults == null ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return const Text("");
    }
    final Size imageSize = Size(cameraController!.value.previewSize!.height,
        cameraController!.value.previewSize!.width);
    CustomPainter custompainter =
        FaceDetectorPainter(imageSize, scanResults, cameraDirection);
    return CustomPaint(
      painter: custompainter,
    );
  }

  toggleCameraToFrontOrBack() async {
    if (cameraDirection == CameraLensDirection.back) {
      cameraDirection = CameraLensDirection.front;
    } else {
      cameraDirection = CameraLensDirection.back;
    }
    await cameraController!.stopImageStream();
    await cameraController!.dispose();
    setState(() {
      cameraController = null;
    });
    initCamera();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackWidgetChildren = [];
    size = MediaQuery.of(context).size;
    if (cameraController != null) {
      stackWidgetChildren.add(
        Positioned(
          top: 0,
          left: 0,
          width: size!.width,
          height: size!.height,
          child: Container(
            child: (cameraController!.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  )
                : Container(),
          ),
        ),
      );
    }
    stackWidgetChildren.add(
      Positioned(
        top: size!.height - 250,
        left: 0,
        width: size!.width,
        height: 250,
        child: Container(
          margin: const EdgeInsets.only(bottom: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  toggleCameraToFrontOrBack();
                },
                icon: const Icon(
                  Icons.cached,
                  color: Colors.white,
                ),
                iconSize: 50,
                color: Colors.black,
              )
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(
          children: stackWidgetChildren,
        ),
      ),
    );
  }
}

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
      this.absoluteImageSize, this.faces, this.cameraLensDirection);
  final Size absoluteImageSize;
  final List<Face> faces;
  CameraLensDirection cameraLensDirection;
  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    final double scaleX = size.width;
    final double scaleY = size.height;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;
    for (Face face in faces) {
      canvas.drawRect(
          Rect.fromLTRB(
            cameraLensDirection == CameraLensDirection.front
                ? (absoluteImageSize.width - face.boundingBox.right) * scaleX
                : face.boundingBox.left * scaleX,
            face.boundingBox.top * scaleY,
            cameraLensDirection == CameraLensDirection.front
                ? (absoluteImageSize.width - face.boundingBox.left) * scaleX
                : face.boundingBox.right * scaleX,
            face.boundingBox.bottom * scaleY,
          ),
          paint);
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}