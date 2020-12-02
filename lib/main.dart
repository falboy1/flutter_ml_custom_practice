import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  ImagePreview preview = ImagePreview();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImagePreview(),
    );
  }
}

class ImagePreview extends StatefulWidget {
  @override
  _ImagePreviewState createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  File _image;
  dynamic _labels;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("Avocado Classifier"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              child: _image == null ? Text('画像を選択してください') : Image.file(_image),
            ),
            Text(_labels[0]['label'] + _labels[0]['confidence'].toString()),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.green,
        child: Container(
          height: 100.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(
                child: Icon(Icons.add_a_photo),
                onPressed: getImageFromCamera,
              ),
              FloatingActionButton(
                child: Icon(Icons.collections),
                onPressed: getImageFromGallery,
              ),
              FloatingActionButton(
                child: Icon(Icons.more),
                onPressed: predictImage,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    setState(() {
      _image = File(pickedFile.path);
    });
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile.path);
    });
  }

  Future<String> loadModel() async {
    Tflite.close();
    return Tflite.loadModel(
      model: "assets/inception_v4.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<dynamic> predictImage() async {
    await loadModel();
    dynamic output =
        await Tflite.runModelOnImage(path: _image.path, threshold: 0.001);
    setState(() {
      _labels = output;
    });
  }
}
