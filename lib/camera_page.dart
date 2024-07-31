
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'result_page.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraReady = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print('No cameras found');
      return;
    }
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller!.initialize();

    try {
      await _initializeControllerFuture;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Take a Photo'),
        centerTitle: true, // Center the title
        backgroundColor: Colors.transparent, // Make the app bar transparent
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady)
            CameraPreview(_controller!)
          else
            Center(child: CircularProgressIndicator()),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Processing image...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: (_isCameraReady && !_isProcessing) ? _takePhoto : null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _takePhoto() async {
    if (!_isCameraReady) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      await _processImage(image);
    } catch (e) {
      print('Error taking photo: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(XFile image) async {
    var uri = Uri.parse('Model_API');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print('response: 200');
        var responseData = await response.stream.bytesToString();
        var result = json.decode(responseData);
        print(result);
        print('vvvv');
        print(result['predicted_class']);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(result: result),
          ),
        );
      } else {
        _showErrorSnackBar('Failed to process image');
      }
    } catch (e) {
      print('Error processing image: $e');
      _showErrorSnackBar('Error processing image');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
