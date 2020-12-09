import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as imgLib;

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
  dynamic _labels = [];
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
            _labels.length == 0
                ? Text("non labels")
                : Expanded(
                    child: ListView.builder(
                      itemCount: _labels.length,
                      itemBuilder: (context, index) {
                        return Text(_labels[index]["label"] +
                            ': ' +
                            _labels[index]["confidence"]);
                      },
                    ),
                  ),
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
      model: "assets/converted_model.tflite",
      labels: "assets/ripe_labels.txt",
    );
  }

  Future<dynamic> predictImage() async {
    await loadModel();
    dynamic output = await Tflite.runModelOnBinary(
        binary: imageToByteListFloat32(224, 224), threshold: 0.001);
    setState(() {
      _labels = output;
    });
  }

  Uint8List imageToByteListFloat32(int width, int height) {
    // imgLibで読み込み
    imgLib.Image image =
        imgLib.decodeImage(File(_image.path).readAsBytesSync());
    // リサイズと複製
    imgLib.Image resizeImage =
        imgLib.copyResize(image, width: width, height: height);
    // Float32のバイトに変換
    var convertedBytes = Float32List(1 * width * height * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        var pixel = resizeImage.getPixel(i, j);
        buffer[pixelIndex++] = (imgLib.getRed(pixel)) / 255;
        buffer[pixelIndex++] = (imgLib.getGreen(pixel)) / 255;
        buffer[pixelIndex++] = (imgLib.getBlue(pixel)) / 255;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
