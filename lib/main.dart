import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home.dart';
import 'package:camera/camera.dart';

List<CameraDescription>? camera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  camera = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FACE DETECTOR APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: home(),
    );
  }
}
