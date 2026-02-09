import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// KYC OCR
import 'package:mnc_identifier_ocr/mnc_identifier_ocr.dart';
import 'package:mnc_identifier_ocr/model/ocr_result_model.dart';

class RegisterPageKtp extends StatefulWidget {
  const RegisterPageKtp({super.key});

  @override
  State<RegisterPageKtp> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPageKtp> {
  // hasil OCR dari plugin
  bool _isScanning = false;
  String? _ktpBase64; // menyimpan image KTP dalam base64
  String? _ktpImagePath;
  String? _parseTanggalKtpToMysql(String raw) {
    if (raw.isEmpty) return null;

    // cari pola dd-mm-yyyy / dd/mm/yyyy / dd.mm.yyyy
    final match = RegExp(
      r'(\d{1,2})[-\/\.](\d{1,2})[-\/\.](\d{2,4})',
    ).firstMatch(raw);

    if (match == null) {
      // kalau format tidak ke-detect, kirim apa adanya saja
      return raw;
    }

    final d = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    final yStr = match.group(3)!;
    int? y = int.tryParse(yStr);

    if (d == null || m == null || y == null) return null;

    // kalau tahun cuma 2 digit
    if (yStr.length == 2) {
      y = (y >= 50) ? (1900 + y) : (2000 + y);
    }

    final date = DateTime(y, m, d);
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // --- state untuk animasi loading & status ---
  bool _isSubmitting = false;
  String? _statusMessage;
  Color _statusColor = Colors.black87;

  // controller data dari KTP
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController tempatLahirController = TextEditingController();
  final TextEditingController tglLahirController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  // data manual
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Ganti IP sesuai alamat backend kamu
  // final String apiUrl = "http://192.168.161.17:3000/api/users/register";
  // contoh:
  final String apiUrl = 'http://192.168.161.17:3000/api/users/register';

  // ---------------------------------------------------------------------------
  // SCAN KTP PAKAI mnc_identifier_ocr
  // ---------------------------------------------------------------------------
  // Future<void> _scanKtp() async {
  //   setState(() => _isScanning = true);

  //   OcrResultModel? res;
  //   try {
  //     res = await MncIdentifierOcr.startCaptureKtp(
  //       withFlash: true,
  //       cameraOnly: true,
  //     );

  //     debugPrint('OCR RESULT: ${res.toJson()}');
  //     debugPrint('KTP image path: ${res.imagePath}');
  //     debugPrint('Face image path: ${res.faceImagePath}');
  //   } catch (e) {
  //     debugPrint('Scan KTP error: $e');
  //   }

  //   if (!mounted) return;

  //   setState(() {
  //     _isScanning = false;
  //   });

  //   // kalau ketemu data KTP, isi ke controller
  //   final ktp = res?.ktp;
  //   if (ktp != null) {
  //     setState(() {
  //       nikController.text = ktp.nik ?? '';
  //       namaController.text = ktp.nama ?? '';
  //       tempatLahirController.text = ktp.tempatLahir ?? '';
  //       tglLahirController.text = ktp.tglLahir ?? '';
  //       alamatController.text = ktp.alamat ?? '';
  //     });
  //   }
  // }

  Future<void> _scanKtp() async {
    setState(() => _isScanning = true);

    OcrResultModel? res;
    try {
      res = await MncIdentifierOcr.startCaptureKtp(
        withFlash: true,
        cameraOnly: true,
      );

      debugPrint('OCR RESULT: ${res.toJson()}');
      debugPrint('KTP image path: ${res.imagePath}');
      debugPrint('Face image path: ${res.faceImagePath}');

      // === BACA FILE KTP & ENCODE BASE64 ===
      // if (res.imagePath != null && res.imagePath!.isNotEmpty) {
      //   final file = File(res.imagePath!);
      //   if (await file.exists()) {
      //     final bytes = await file.readAsBytes();
      //     _ktpBase64 = base64Encode(bytes); // ⬅️ disimpan di state
      //     debugPrint(
      //       "Berhasil encode KTP ke base64, length=${_ktpBase64!.length}",
      //     );
      //   } else {
      //     debugPrint("File KTP tidak ditemukan di path: ${res.imagePath}");
      //   }
      // }
      if (res.imagePath != null && res.imagePath!.isNotEmpty) {
        _ktpImagePath = res.imagePath!;
        debugPrint(">> KTP path disimpan: $_ktpImagePath");
      }
    } catch (e) {
      debugPrint('Scan KTP error: $e');
    }

    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    // kalau ketemu data KTP, isi ke controller
    final ktp = res?.ktp;
    if (ktp != null) {
      setState(() {
        nikController.text = ktp.nik ?? '';
        namaController.text = ktp.nama ?? '';
        tempatLahirController.text = ktp.tempatLahir ?? '';
        tglLahirController.text = ktp.tglLahir ?? '';
        alamatController.text = ktp.alamat ?? '';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // KIRIM DATA KE BACKEND (+ animasi status)
  // ---------------------------------------------------------------------------
  // Future<void> _registerUser() async {
  //   debugPrint(">>> [_registerUser] dipanggil");

  //   // validasi basic
  //   if (nikController.text.isEmpty ||
  //       namaController.text.isEmpty ||
  //       usernameController.text.isEmpty ||
  //       passwordController.text.isEmpty ||
  //       confirmPasswordController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Lengkapi data terlebih dahulu")),
  //     );
  //     return;
  //   }

  //   if (passwordController.text != confirmPasswordController.text) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Password dan konfirmasi tidak sama")),
  //     );
  //     return;
  //   }

  //   // if (_ktpImagePath == null) {
  //   //   ScaffoldMessenger.of(context).showSnackBar(
  //   //     const SnackBar(
  //   //       content: Text("Silakan scan / foto KTP terlebih dahulu"),
  //   //     ),
  //   //   );
  //   //   return;
  //   // }

  //   // format tanggal lahir kalau mau rapi (opsional)
  //   final tanggalMysql = _parseTanggalKtpToMysql(tglLahirController.text);

  //   setState(() {
  //     _isSubmitting = true;
  //     _statusMessage = "Mengirim data registrasi, tunggu sebentar...";
  //     _statusColor = Colors.black87;
  //   });

  //   try {
  //     final uri = Uri.parse(apiUrl);
  //     debugPrint(">>> [HTTP] POST multipart ke $uri");

  //     final request = http.MultipartRequest("POST", uri);

  //     // field text
  //     request.fields.addAll({
  //       "nik": nikController.text,
  //       "nama": namaController.text,
  //       "alamat": alamatController.text,
  //       "username": usernameController.text,
  //       "password": passwordController.text,
  //       "phone": phoneController.text,
  //       "tempat_lahir": tempatLahirController.text,
  //       "tanggal_lahir": tanggalMysql ?? tglLahirController.text,
  //       // kalau nanti pakai email tinggal tambah
  //       // "email": emailController.text,
  //     });

  //     // file KTP
  //     // request.files.add(
  //     //   await http.MultipartFile.fromPath(
  //     //     "ktp_image", // ⬅️ harus sama dengan upload.single("ktp_image")
  //     //     _ktpImagePath!,
  //     //     filename: "ktp_${nikController.text}.jpg",
  //     //   ),
  //     // );

  //     // kirim & kasih timeout
  //     final streamedResponse = await request.send().timeout(
  //       const Duration(seconds: 60),
  //     );

  //     final response = await http.Response.fromStream(streamedResponse);
  //     debugPrint(">>> [HTTP] statusCode: ${response.statusCode}");
  //     debugPrint(">>> [HTTP] body: ${response.body}");

  //     dynamic result;
  //     try {
  //       result = jsonDecode(response.body);
  //     } catch (_) {
  //       result = null;
  //     }

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       setState(() {
  //         _statusMessage = "Registrasi berhasil! 🎉";
  //         _statusColor = Colors.green;
  //       });

  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text("Registrasi berhasil!")));

  //       await Future.delayed(const Duration(seconds: 1));
  //       if (mounted) Navigator.pop(context);
  //     } else {
  //       final msg = (result != null && result["message"] != null)
  //           ? result["message"]
  //           : "Terjadi kesalahan (status ${response.statusCode})";

  //       setState(() {
  //         _statusMessage = "Registrasi gagal: $msg";
  //         _statusColor = Colors.red;
  //       });

  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("Gagal: $msg")));
  //     }
  //   } on TimeoutException catch (e) {
  //     debugPrint(">>> [ERROR] TimeoutException: $e");
  //     if (!mounted) return;
  //     setState(() {
  //       _statusMessage =
  //           "Timeout: server tidak merespon (cek IP, port, dan backend).";
  //       _statusColor = Colors.red;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Timeout: server tidak merespon, coba lagi."),
  //       ),
  //     );
  //   } on SocketException catch (e) {
  //     debugPrint(">>> [ERROR] SocketException: $e");
  //     if (!mounted) return;
  //     setState(() {
  //       _statusMessage =
  //           "Tidak bisa terhubung ke server (cek WiFi/IP backend).";
  //       _statusColor = Colors.red;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Tidak bisa terhubung ke server: $e")),
  //     );
  //   } catch (e) {
  //     debugPrint(">>> [ERROR] Exception umum: $e");
  //     if (!mounted) return;
  //     setState(() {
  //       _statusMessage = "Terjadi kesalahan: $e";
  //       _statusColor = Colors.red;
  //     });
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Error: $e")));
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isSubmitting = false;
  //       });
  //     }
  //   }
  // }
  Future<void> _registerUser() async {
    debugPrint(">>> [_registerUser] dipanggil");

    // validasi basic
    if (nikController.text.isEmpty ||
        namaController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi data terlebih dahulu")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password dan konfirmasi tidak sama")),
      );
      return;
    }

    // WAJIB: sudah scan / foto KTP
    if (_ktpImagePath == null || _ktpImagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Silakan scan / foto KTP terlebih dahulu"),
        ),
      );
      return;
    }

    // format tanggal lahir (kalau kamu punya helper _parseTanggalKtpToMysql)
    final tanggalMysql = _parseTanggalKtpToMysql(tglLahirController.text);

    setState(() {
      _isSubmitting = true;
      _statusMessage = "Mengirim data registrasi, tunggu sebentar...";
      _statusColor = Colors.black87;
    });

    try {
      final uri = Uri.parse(apiUrl);
      debugPrint(">>> [HTTP] POST multipart ke $uri");

      final request = http.MultipartRequest("POST", uri);

      // field text
      request.fields.addAll({
        "nik": nikController.text,
        "nama": namaController.text,
        "alamat": alamatController.text,
        "username": usernameController.text,
        "password": passwordController.text,
        "phone": phoneController.text,
        "tempat_lahir": tempatLahirController.text,
        "tanggal_lahir": tanggalMysql ?? tglLahirController.text,
      });

      // file KTP
      request.files.add(
        await http.MultipartFile.fromPath(
          "ktp_image", // harus sama dengan upload.single("ktp_image") di backend
          _ktpImagePath!,
          filename: "ktp_${nikController.text}.jpg",
        ),
      );

      // kirim (kalau mau test, hapus dulu .timeout)
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint(">>> [HTTP] statusCode: ${response.statusCode}");
      debugPrint(">>> [HTTP] body: ${response.body}");

      dynamic result;
      try {
        result = jsonDecode(response.body);
      } catch (_) {
        result = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _statusMessage = "Registrasi berhasil! 🎉";
          _statusColor = Colors.green;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Registrasi berhasil!")));

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        final msg = (result != null && result["message"] != null)
            ? result["message"]
            : "Terjadi kesalahan (status ${response.statusCode})";

        setState(() {
          _statusMessage = "Registrasi gagal: $msg";
          _statusColor = Colors.red;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $msg")));
      }
    } on TimeoutException catch (e) {
      debugPrint(">>> [ERROR] TimeoutException: $e");
      if (!mounted) return;
      setState(() {
        _statusMessage =
            "Timeout: server tidak merespon (cek IP, port, dan backend).";
        _statusColor = Colors.red;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Timeout: server tidak merespon, coba lagi."),
        ),
      );
    } on SocketException catch (e) {
      debugPrint(">>> [ERROR] SocketException: $e");
      if (!mounted) return;
      setState(() {
        _statusMessage =
            "Tidak bisa terhubung ke server (cek WiFi/IP backend).";
        _statusColor = Colors.red;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak bisa terhubung ke server: $e")),
      );
    } catch (e) {
      debugPrint(">>> [ERROR] Exception umum: $e");
      if (!mounted) return;
      setState(() {
        _statusMessage = "Terjadi kesalahan: $e";
        _statusColor = Colors.red;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    namaController.dispose();
    nikController.dispose();
    tempatLahirController.dispose();
    tglLahirController.dispose();
    alamatController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------
  Widget _greyKtpField({
    required TextEditingController controller,
    required String hint,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: 'Masukkan $label',
          labelText: label,
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _whiteField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrasi Akun"),
        backgroundColor: const Color(0xFF8B5A24), // coklat
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Logo (ganti asset sesuai punya kamu)
              SizedBox(
                height: 120,
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Scan KTP (pakai plugin OCR)
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanKtp,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFF3F3F3),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: _isScanning
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(_isScanning ? "Memindai KTP..." : "Scan KTP"),
              ),
              const SizedBox(height: 24),

              // Title Data dari KTP
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Data Dari KTP",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Field abu-abu (hasil scan tapi tetap bisa diedit)
              _greyKtpField(
                controller: namaController,
                hint: "Nama Lengkap",
                label: "Nama Lengkap",
              ),
              _greyKtpField(
                controller: nikController,
                hint: "NIK",
                label: "Nomor Induk Kependudukan",
                keyboardType: TextInputType.number,
              ),
              _greyKtpField(
                controller: tempatLahirController,
                hint: "Tempat Lahir",
                label: "Tempat Lahir",
              ),
              _greyKtpField(
                controller: tglLahirController,
                hint: "Tanggal Lahir",
                label: "Tanggal Lahir",
              ),
              _greyKtpField(
                controller: alamatController,
                hint: "Alamat",
                label: "Alamat",
                maxLines: 2,
              ),

              const SizedBox(height: 8),

              // Field putih (input manual)
              _whiteField(
                controller: phoneController,
                hint: "Nomor Handphone",
                keyboardType: TextInputType.phone,
              ),
              _whiteField(controller: usernameController, hint: "Username"),
              _whiteField(
                controller: passwordController,
                hint: "Password",
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              _whiteField(
                controller: confirmPasswordController,
                hint: "Ulangi Password",
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Tombol daftar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5A24), // coklat
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Daftar Sekarang",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // Animasi teks status (loading / sukses / error)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _statusMessage != null
                    ? Text(
                        _statusMessage!,
                        key: const ValueKey("statusText"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
