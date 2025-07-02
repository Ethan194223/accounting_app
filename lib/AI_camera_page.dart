// lib/ai_camera_page.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A screen that shows a live camera preview and runs ML Kit text
/// recognition every second. Tapping the check icon will pop this
/// screen and return the last-recognised text.
class LiveOCRScreen extends StatefulWidget {
  const LiveOCRScreen({Key? key}) : super(key: key);

  @override
  State<LiveOCRScreen> createState() => _LiveOCRScreenState();
}

class _LiveOCRScreenState extends State<LiveOCRScreen> {
  CameraController? _controller;
  Timer? _ocrTimer;
  String _recognizedText = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // 1️⃣ Fetch available cameras on the device
      final cameras = await availableCameras();
      if (!mounted || cameras.isEmpty) return;

      // 2️⃣ Initialise the controller with the first (back) camera
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {}); // rebuild to show the preview

      // 3️⃣ Start an OCR loop
      _ocrTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) => _runTextRecognition(),
      );
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _runTextRecognition() async {
    if (_busy || _controller == null || !_controller!.value.isInitialized) return;
    _busy = true;

    try {
      // 1️⃣ Grab a picture
      final XFile snapshot = await _controller!.takePicture();

      // 2️⃣ Run ML Kit OCR on it
      final inputImage = InputImage.fromFilePath(snapshot.path);
      final recognizer = TextRecognizer();
      final result = await recognizer.processImage(inputImage);

      // 3️⃣ Update the overlay text
      if (mounted) setState(() => _recognizedText = result.text);

      // 4️⃣ Clean up
      await recognizer.close();
      await File(snapshot.path).delete();
    } catch (e) {
      debugPrint('OCR error: $e');
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _ocrTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live OCR'),
        actions: [
          // ✅ Return the recognised text when tapped
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Use this text',
            onPressed: () {
              Navigator.of(context).pop(_recognizedText);
            },
          )
        ],
      ),
      body: cam == null || !cam.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CameraPreview(cam),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                _recognizedText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

