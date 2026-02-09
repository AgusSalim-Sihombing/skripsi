import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class TestingPage extends StatefulWidget {
  static const routeName = '/testing/testing-upload';

  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isUploading = false;
  String? _statusMessage;

  // GANTI sesuai IP / base url backend kamu
  // - emulator Android: 10.0.2.2
  // - device real: IP laptop, misal: 192.168.1.5
  static const String baseUrl = 'http://192.168.91.17:3000';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // biar ga terlalu berat
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _statusMessage = null;
        });
      }
    } catch (e) {
      debugPrint("Error pick image: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memilih gambar: $e")));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih gambar dulu")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = null;
    });

    try {
      final uri = Uri.parse('$baseUrl/testing/testing-upload');

      final request = http.MultipartRequest('POST', uri);

      // IMPORTANT: field name harus "gambar" (sesuai multer.single("gambar"))
      request.files.add(
        await http.MultipartFile.fromPath('gambar', _selectedImage!.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Status code: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        String msg = "Gambar berhasil diupload";

        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        } catch (_) {
          // kalau bukan JSON valid, skip aja
        }

        setState(() {
          _statusMessage = msg;
          _selectedImage = null;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        String msg = "Gagal upload gambar (code: ${response.statusCode})";
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _statusMessage = msg;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      debugPrint("Error upload: $e");
      if (!mounted) return;

      setState(() {
        _statusMessage = "Error upload: $e";
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error upload: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Testing Upload Gambar")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview gambar
            Expanded(
              child: Center(
                child: _selectedImage == null
                    ? Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Belum ada gambar dipilih",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Status text
            if (_statusMessage != null) ...[
              Text(
                _statusMessage!,
                style: TextStyle(
                  color:
                      _statusMessage!.toLowerCase().contains("gagal") ||
                          _statusMessage!.toLowerCase().contains("error")
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tombol pilih gambar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text("Galeri"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text("Kamera"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tombol upload
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                icon: _isUploading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? "Uploading..." : "Upload Gambar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
