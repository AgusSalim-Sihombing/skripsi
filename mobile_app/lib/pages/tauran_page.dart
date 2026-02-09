import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart'; // 📸 Tambahan untuk baca metadata EXIF

class TauranPage extends StatefulWidget {
  const TauranPage({super.key});

  @override
  State<TauranPage> createState() => _TauranPageState();
}

class _TauranPageState extends State<TauranPage> {
  File? imageFile;
  Map<String, IfdTag> exifData = {}; // Menyimpan metadata
  final ImagePicker _picker = ImagePicker();

  // Fungsi ambil gambar dari kamera
  Future<void> _getFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxHeight: 1000,
      maxWidth: 1000,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await pickedFile.readAsBytes();

      // 🔍 Baca metadata (EXIF)
      final tags = await readExifFromBytes(bytes);

      setState(() {
        imageFile = file;
        exifData = tags;
      });

      if (tags.isEmpty) {
        debugPrint("❌ Tidak ada metadata EXIF ditemukan.");
      } else {
        debugPrint("✅ Metadata ditemukan:");
        for (var entry in tags.entries) {
          debugPrint("${entry.key}: ${entry.value}");
        }
      }
    }
  }

  // Konversi DMS ke derajat desimal
  double _convertToDegree(List values) {
    return values[0].toDouble() +
        (values[1].toDouble() / 60) +
        (values[2].toDouble() / 3600);
  }

  // Ambil koordinat GPS dari EXIF
  String? _getGpsCoordinates() {
    if (exifData.containsKey('GPSLatitude') &&
        exifData.containsKey('GPSLongitude')) {
      final latValues = exifData['GPSLatitude']?.values.toList();
      final lonValues = exifData['GPSLongitude']!.values.toList();
      final latRef = exifData['GPSLatitudeRef']?.printable ?? 'N';
      final lonRef = exifData['GPSLongitudeRef']?.printable ?? 'E';

      if (latValues != null) {
        double lat = _convertToDegree(latValues);
        double lon = _convertToDegree(lonValues);

        if (latRef == 'S') lat = -lat;
        if (lonRef == 'W') lon = -lon;

        return "$lat, $lon";
      }
    }
    return null; 
  }

  @override
  Widget build(BuildContext context) {
    final gps = _getGpsCoordinates();
    final dateTime = exifData['DateTime']?.printable ?? 'Tidak tersedia';
    final cameraModel = exifData['Model']?.printable ?? 'Tidak diketahui';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tawuran"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Preview image
              if (imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: Image.file(
                    imageFile!,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.image_outlined, size: 120, color: Colors.grey),

              const SizedBox(height: 20.0),

              ElevatedButton.icon(
                onPressed: _getFromCamera,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'Ambil Gambar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30.0),

              // 🧾 Metadata hasil foto
              if (imageFile != null) ...[
                const Text(
                  "📋 Metadata Foto",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow("Tanggal/Waktu", dateTime),
                _buildInfoRow("Model Kamera", cameraModel),
                _buildInfoRow("Koordinat GPS", gps ?? "Tidak tersedia"),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget kecil untuk menampilkan baris info
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
