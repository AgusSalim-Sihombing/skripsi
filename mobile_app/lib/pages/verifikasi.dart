import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:mnc_identifier_ocr/mnc_identifier_ocr.dart';
import 'package:mnc_identifier_ocr/model/ocr_result_model.dart';

class ScanKTP extends StatefulWidget {
  const ScanKTP({super.key});

  @override
  State<ScanKTP> createState() => _ScanKTPState();
}

class _ScanKTPState extends State<ScanKTP> {
  OcrResultModel? _result;
  bool _isLoading = false;

  // --- SCAN KTP ---
  Future<void> _scanKtp() async {
    setState(() => _isLoading = true);

    OcrResultModel? res;
    try {
      res = await MncIdentifierOcr.startCaptureKtp(
        withFlash: true,
        cameraOnly: true,
      );
      debugPrint('result: ${res.toJson()}');
      debugPrint('KTP image path: ${res.imagePath}');
      debugPrint('Face image path: ${res.faceImagePath}');
    } catch (e) {
      debugPrint('something goes wrong $e');
    }

    if (!mounted) return;

    setState(() {
      _result = res;
      _isLoading = false;
    });
  }

  // --- PICK DARI GALLERY ---
  Future<void> _imgGlr() async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    debugPrint('path (gallery): ${image?.path}');
  }

  // --- CAPTURE DARI CAMERA ---
  Future<void> _imgCmr() async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.camera);
    debugPrint('path (camera): ${image?.path}');
  }

  @override
  Widget build(BuildContext context) {
    final ktp = _result?.ktp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan KTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _scanKtp,
              child: const Text('Scan KTP'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _imgGlr,
              child: const Text('Pick Image from Gallery'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _imgCmr,
              child: const Text('Capture Image from Camera'),
            ),
            const SizedBox(height: 24),

            if (_isLoading) const CircularProgressIndicator(),

            const SizedBox(height: 16),

            _result == null
                ? const Text('No data scanned yet.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NIK   : ${ktp?.nik ?? "-"}'),
                      Text('Nama  : ${ktp?.nama ?? "-"}'),
                      Text('TTL   : ${ktp?.tempatLahir ?? "-"}, ${ktp?.tglLahir ?? "-"}'),
                      Text('Alamat: ${ktp?.alamat ?? "-"}'),
                      const SizedBox(height: 8),
                      Text('Raw JSON:\n${_result!.toJson()}'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
