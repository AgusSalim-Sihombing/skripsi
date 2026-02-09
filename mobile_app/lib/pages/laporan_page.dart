import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/api_config.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // final uri = Uri.parse('http://10.0.2.2:3001/laporan');
    final uri = Uri.parse('${ApiConfig.baseUrl}/laporan');

    var request = http.MultipartRequest('POST', uri);
    request.fields['judul'] = _judulController.text;
    request.fields['deskripsi'] = _deskripsiController.text;
    request.fields['lokasi'] = _lokasiController.text;

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', _imageFile!.path),
      );
    }

    var response = await request.send();
    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil dikirim!")),
      );
      _formKey.currentState!.reset();
      setState(() => _imageFile = null);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mengirim laporan.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Kejahatan"),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Isi detail laporan kejahatan di bawah ini:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: "Judul Kejahatan",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Judul wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi Kejadian",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Deskripsi wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: "Lokasi Kejadian",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Lokasi wajib diisi" : null,
              ),
              const SizedBox(height: 20),

              _imageFile == null
                  ? const Text("Belum ada foto diunggah.")
                  : Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              const SizedBox(height: 10),

              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Ambil Foto"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLaporan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "KIRIM LAPORAN",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
