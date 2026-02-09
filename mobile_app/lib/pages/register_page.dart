// import 'dart:io';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:mobile_app/config/api_config.dart';
// class RegisterPage extends StatefulWidget {
//   const RegisterPage({super.key});

//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   final picker = ImagePicker();

//   File? _ktpImage;

//   // controller data identitas
//   final TextEditingController namaController = TextEditingController();
//   final TextEditingController nikController = TextEditingController();
//   final TextEditingController tempatLahirController = TextEditingController();
//   final TextEditingController tglLahirController = TextEditingController();
//   final TextEditingController alamatController = TextEditingController();

//   // data manual tambahan
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController usernameController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   bool _isSubmitting = false;
//   String? _statusMessage;
//   Color _statusColor = Colors.black87;

//   // Ganti IP sesuai alamat backend kamu
//   // pastikan route Node.js kamu: POST /api/users/register -> userController.createUser
//   // final String apiUrl = "http://10.176.170.17:3000/api/users/register";

//   // Ambil gambar KTP dari kamera (tanpa OCR)
//   Future<void> _pickImage() async {
//     final pickedFile = await picker.pickImage(
//       source: ImageSource.camera,
//       imageQuality: 80,
//     );
//     if (pickedFile != null) {
//       setState(() {
//         _ktpImage = File(pickedFile.path);
//       });
//     }
//   }

//   // ==== HELPER: konversi tgl lahir ke format MySQL (YYYY-MM-DD) ====
//   String? _parseTanggalKtpToMysql(String raw) {
//     if (raw.isEmpty) return null;

//     // cari pola dd-mm-yyyy / dd/mm/yyyy / dd.mm.yyyy
//     final match = RegExp(
//       r'(\d{1,2})[-\/\.](\d{1,2})[-\/\.](\d{2,4})',
//     ).firstMatch(raw);

//     if (match == null) {
//       // kalau format gak ke-detect, kirim apa adanya saja (backend bisa handle)
//       return raw;
//     }

//     final d = int.tryParse(match.group(1)!);
//     final m = int.tryParse(match.group(2)!);
//     final yStr = match.group(3)!;
//     int? y = int.tryParse(yStr);

//     if (d == null || m == null || y == null) return null;

//     // handle kalau tahun cuma 2 digit
//     if (yStr.length == 2) {
//       // logika simpel: >=50 -> 1900an, else -> 2000an
//       y = (y >= 50) ? (1900 + y) : (2000 + y);
//     }

//     final date = DateTime(y, m, d);
//     return "${date.year.toString().padLeft(4, '0')}-"
//         "${date.month.toString().padLeft(2, '0')}-"
//         "${date.day.toString().padLeft(2, '0')}";
//   }

//   // Kirim data ke backend
//   Future<void> _registerUser() async {
//     // Validasi awal
//     if (nikController.text.isEmpty ||
//         namaController.text.isEmpty ||
//         alamatController.text.isEmpty ||
//         usernameController.text.isEmpty ||
//         passwordController.text.isEmpty ||
//         confirmPasswordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Lengkapi semua data wajib terlebih dahulu")),
//       );
//       return;
//     }

//     if (passwordController.text != confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Password dan konfirmasi tidak sama")),
//       );
//       return;
//     }

//     // Pastikan user sudah foto KTP
//     if (_ktpImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Silakan foto KTP terlebih dahulu"),
//         ),
//       );
//       return;
//     }

//     // format tanggal lahir ke YYYY-MM-DD
//     final String? tanggalMysql = _parseTanggalKtpToMysql(
//       tglLahirController.text,
//     );

//     // === Baca file KTP & encode base64 ===
//     final bytes = await _ktpImage!.readAsBytes();
//     final String ktpBase64 = base64Encode(bytes);
//     // kalau backend nanti butuh prefix, tinggal:
//     // final String ktpBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";

//     final body = {
//       "nik": nikController.text.trim(),
//       "nama": namaController.text.trim(),
//       "alamat": alamatController.text.trim(),
//       "username": usernameController.text.trim(),
//       "password": passwordController.text,
//       "phone": phoneController.text.trim(),
//       "tempat_lahir": tempatLahirController.text.trim(),
//       "tanggal_lahir": tanggalMysql,
//       "ktp_image": ktpBase64, // ⬅️ dikirim ke backend
//     };

//     setState(() {
//       _isSubmitting = true;
//       _statusMessage = "Mengirim data registrasi...";
//       _statusColor = Colors.black87;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/users/register'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );

//       dynamic result;
//       try {
//         result = jsonDecode(response.body);
//       } catch (_) {
//         result = null;
//       }

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         setState(() {
//           _statusMessage = "Registrasi berhasil! 🎉";
//           _statusColor = Colors.green;
//         });

//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Registrasi berhasil!")));

//         await Future.delayed(const Duration(seconds: 1));
//         if (mounted) Navigator.pop(context);
//       } else {
//         final msg = (result != null && result["message"] != null)
//             ? result["message"]
//             : "Terjadi kesalahan (status ${response.statusCode})";

//         setState(() {
//           _statusMessage = "Registrasi gagal: $msg";
//           _statusColor = Colors.red;
//         });

//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Gagal: $msg")));
//       }
//     } catch (e) {
//       setState(() {
//         _statusMessage = "Tidak bisa terhubung ke server: $e";
//         _statusColor = Colors.red;
//       });

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSubmitting = false;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     namaController.dispose();
//     nikController.dispose();
//     tempatLahirController.dispose();
//     tglLahirController.dispose();
//     alamatController.dispose();
//     phoneController.dispose();
//     usernameController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     super.dispose();
//   }

//   // ---------- UI HELPER ----------

//   Widget _greyKtpField({
//     required TextEditingController controller,
//     required String hint,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           hintText: hint,
//           filled: true,
//           fillColor: const Color(0xFFE3E3E3),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 14,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _whiteField({
//     required TextEditingController controller,
//     required String hint,
//     TextInputType? keyboardType,
//     bool obscureText = false,
//     Widget? suffixIcon,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         obscureText: obscureText,
//         decoration: InputDecoration(
//           hintText: hint,
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//           ),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 14,
//           ),
//           suffixIcon: suffixIcon,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Registrasi Akun"),
//         backgroundColor: const Color(0xFF8B5A24), // coklat
//       ),
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 12),
//               SizedBox(
//                 height: 120,
//                 child: Center(
//                   child: Image.asset(
//                     'assets/logo.png',
//                     height: 110,
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),

//               // Tombol Foto KTP
//               ElevatedButton.icon(
//                 onPressed: _pickImage,
//                 style: ElevatedButton.styleFrom(
//                   elevation: 0,
//                   backgroundColor: const Color(0xFFF3F3F3),
//                   foregroundColor: Colors.black87,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 8,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 icon: const Icon(Icons.camera_alt_outlined, size: 18),
//                 label: const Text("Foto KTP"),
//               ),

//               if (_ktpImage != null) ...[
//                 const SizedBox(height: 8),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.file(
//                     _ktpImage!,
//                     height: 160,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ],

//               const SizedBox(height: 24),

//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: const Text(
//                   "Data Identitas",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               _greyKtpField(controller: namaController, hint: "Nama Lengkap"),
//               _greyKtpField(
//                 controller: nikController,
//                 hint: "NIK",
//                 keyboardType: TextInputType.number,
//               ),
//               _greyKtpField(
//                 controller: tempatLahirController,
//                 hint: "Tempat Lahir",
//               ),
//               _greyKtpField(
//                 controller: tglLahirController,
//                 hint: "Tanggal Lahir (contoh: 08-08-2003)",
//               ),
//               _greyKtpField(
//                 controller: alamatController,
//                 hint: "Alamat",
//                 maxLines: 2,
//               ),

//               const SizedBox(height: 8),

//               _whiteField(
//                 controller: phoneController,
//                 hint: "Nomor Handphone",
//                 keyboardType: TextInputType.phone,
//               ),
//               _whiteField(controller: usernameController, hint: "Username"),
//               _whiteField(
//                 controller: passwordController,
//                 hint: "Password",
//                 obscureText: _obscurePassword,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscurePassword
//                         ? Icons.visibility_off_outlined
//                         : Icons.visibility_outlined,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _obscurePassword = !_obscurePassword;
//                     });
//                   },
//                 ),
//               ),
//               _whiteField(
//                 controller: confirmPasswordController,
//                 hint: "Ulangi Password",
//                 obscureText: _obscureConfirmPassword,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscureConfirmPassword
//                         ? Icons.visibility_off_outlined
//                         : Icons.visibility_outlined,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _obscureConfirmPassword = !_obscureConfirmPassword;
//                     });
//                   },
//                 ),
//               ),

//               const SizedBox(height: 16),

//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed:
//                       _isSubmitting ? null : _registerUser, // disable saat loading
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF8B5A24), // coklat
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   child: _isSubmitting
//                       ? const SizedBox(
//                           height: 18,
//                           width: 18,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               Colors.white,
//                             ),
//                           ),
//                         )
//                       : const Text(
//                           "Daftar Sekarang",
//                           style: TextStyle(
//                             color: Color.fromARGB(255, 255, 255, 255),
//                           ),
//                         ),
//                 ),
//               ),

//               const SizedBox(height: 8),

//               AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 child: _isSubmitting
//                     ? Row(
//                         key: const ValueKey("loading"),
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: const [
//                           SizedBox(
//                             height: 18,
//                             width: 18,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           ),
//                           SizedBox(width: 8),
//                           Text("Sedang memproses, mohon tunggu..."),
//                         ],
//                       )
//                     : (_statusMessage != null
//                         ? Text(
//                             _statusMessage!,
//                             key: const ValueKey("status"),
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: _statusColor,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           )
//                         : const SizedBox.shrink()),
//               ),

//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text(
//                   "Login",
//                   style: TextStyle(color: Colors.black87),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final picker = ImagePicker();

  File? _ktpImage; // foto KTP (wajib)
  File?
  _buktiOfficerImage; // bukti polisi (khusus kalau daftar sebagai officer)

  // controller data identitas
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController tempatLahirController = TextEditingController();
  final TextEditingController tglLahirController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  // data manual tambahan
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // data khusus officer
  final TextEditingController nrpController = TextEditingController();
  final TextEditingController pangkatController = TextEditingController();
  final TextEditingController satuanController = TextEditingController();

  // role yang dipilih: 'masyarakat' / 'officer'
  String _selectedRole = 'masyarakat';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isSubmitting = false;
  String? _statusMessage;
  Color _statusColor = Colors.black87;

  // Ambil gambar KTP dari kamera
  Future<void> _pickKtpImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _ktpImage = File(pickedFile.path);
      });
    }
  }

  // Ambil bukti officer (kartu anggota / surat tugas)
  Future<void> _pickBuktiOfficerImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _buktiOfficerImage = File(pickedFile.path);
      });
    }
  }

  // ==== HELPER: konversi tgl lahir ke format MySQL (YYYY-MM-DD) ====
  String? _parseTanggalKtpToMysql(String raw) {
    if (raw.isEmpty) return null;

    final match = RegExp(
      r'(\d{1,2})[-\/\.](\d{1,2})[-\/\.](\d{2,4})',
    ).firstMatch(raw);

    if (match == null) return raw;

    final d = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    final yStr = match.group(3)!;
    int? y = int.tryParse(yStr);

    if (d == null || m == null || y == null) return null;

    if (yStr.length == 2) {
      y = (y >= 50) ? (1900 + y) : (2000 + y);
    }

    final date = DateTime(y, m, d);
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // Kirim data ke backend
  Future<void> _registerUser() async {
    // Validasi awal (wajib)
    if (nikController.text.isEmpty ||
        namaController.text.isEmpty ||
        alamatController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data wajib terlebih dahulu"),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password dan konfirmasi tidak sama")),
      );
      return;
    }

    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan foto KTP terlebih dahulu")),
      );
      return;
    }

    // Validasi khusus kalau pilih officer
    if (_selectedRole == 'officer') {
      if (nrpController.text.isEmpty ||
          pangkatController.text.isEmpty ||
          satuanController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("NRP, Pangkat, dan Satuan wajib diisi untuk officer"),
          ),
        );
        return;
      }

      if (_buktiOfficerImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Silakan foto bukti bahwa Anda petugas (kartu / surat)",
            ),
          ),
        );
        return;
      }
    }

    final String? tanggalMysql = _parseTanggalKtpToMysql(
      tglLahirController.text,
    );

    setState(() {
      _isSubmitting = true;
      _statusMessage = "Mengirim data registrasi...";
      _statusColor = Colors.black87;
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/register');

      // Pake MultipartRequest karena kita kirim FILE (ktp_image, bukti_officer)
      final request = http.MultipartRequest('POST', uri);

      // field teks
      request.fields.addAll({
        "nik": nikController.text.trim(),
        "nama": namaController.text.trim(),
        "alamat": alamatController.text.trim(),
        "username": usernameController.text.trim(),
        "password": passwordController.text,
        "phone": phoneController.text.trim(),
        "tempat_lahir": tempatLahirController.text.trim(),
        "tanggal_lahir": tanggalMysql ?? "",
        "role_request": _selectedRole, // 'masyarakat' / 'officer'
      });

      if (_selectedRole == 'officer') {
        request.fields["nrp"] = nrpController.text.trim();
        request.fields["pangkat"] = pangkatController.text.trim();
        request.fields["satuan"] = satuanController.text.trim();
      }

      // FILE: foto KTP
      request.files.add(
        await http.MultipartFile.fromPath(
          'ktp_image',
          _ktpImage!.path,
          filename: 'ktp_${nikController.text.trim()}.jpg',
        ),
      );

      // FILE: bukti officer (kalau daftar officer)
      if (_selectedRole == 'officer' && _buktiOfficerImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'bukti_officer',
            _buktiOfficerImage!.path,
            filename: 'bukti_officer_${nikController.text.trim()}.jpg',
          ),
        );
      }

      // optional: accept header
      request.headers['Accept'] = 'application/json';

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      dynamic result;
      try {
        result = jsonDecode(response.body);
      } catch (_) {
        result = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _statusMessage = (result != null && result["message"] != null)
              ? result["message"]
              : "Registrasi berhasil! 🎉";
          _statusColor = Colors.green;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (result != null && result["message"] != null)
                  ? result["message"]
                  : "Registrasi berhasil!",
            ),
          ),
        );

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
    } catch (e) {
      setState(() {
        _statusMessage = "Tidak bisa terhubung ke server: $e";
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
    nrpController.dispose();
    pangkatController.dispose();
    satuanController.dispose();
    super.dispose();
  }

  // ---------- UI HELPER ----------

  Widget _greyKtpField({
    required TextEditingController controller,
    required String hint,
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
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFE3E3E3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
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

  @override
  Widget build(BuildContext context) {
    final isOfficer = _selectedRole == 'officer';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrasi Akun"),
        backgroundColor: const Color(0xFF8B5A24),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
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

              // PILIH ROLE
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Daftar sebagai",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Masyarakat"),
                      selected: _selectedRole == 'masyarakat',
                      selectedColor: const Color(0xFF8B5A24),
                      labelStyle: TextStyle(
                        color: _selectedRole == 'masyarakat'
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedRole = 'masyarakat';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Officer (Polisi)"),
                      selected: _selectedRole == 'officer',
                      selectedColor: const Color(0xFF8B5A24),
                      labelStyle: TextStyle(
                        color: _selectedRole == 'officer'
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedRole = 'officer';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tombol Foto KTP
              ElevatedButton.icon(
                onPressed: _pickKtpImage,
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
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text("Foto KTP"),
              ),

              if (_ktpImage != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_ktpImage!, height: 160, fit: BoxFit.cover),
                ),
              ],

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Data Identitas",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),

              _greyKtpField(controller: namaController, hint: "Nama Lengkap"),
              _greyKtpField(
                controller: nikController,
                hint: "NIK",
                keyboardType: TextInputType.number,
              ),
              _greyKtpField(
                controller: tempatLahirController,
                hint: "Tempat Lahir",
              ),
              _greyKtpField(
                controller: tglLahirController,
                hint: "Tanggal Lahir (contoh: 08-08-2003)",
              ),
              _greyKtpField(
                controller: alamatController,
                hint: "Alamat",
                maxLines: 2,
              ),

              const SizedBox(height: 8),

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

              // FORM KHUSUS OFFICER
              if (isOfficer) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Data Keanggotaan (Officer)",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _whiteField(
                  controller: nrpController,
                  hint: "NRP / Nomor Induk",
                ),
                _whiteField(controller: pangkatController, hint: "Pangkat"),
                _whiteField(
                  controller: satuanController,
                  hint: "Satuan / Unit",
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Bukti bahwa Anda petugas (foto kartu anggota / surat tugas)",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: _pickBuktiOfficerImage,
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
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text("Foto Bukti Officer"),
                ),
                if (_buktiOfficerImage != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _buktiOfficerImage!,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : _registerUser, // disable saat loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5A24),
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

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSubmitting
                    ? Row(
                        key: const ValueKey("loading"),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text("Sedang memproses, mohon tunggu..."),
                        ],
                      )
                    : (_statusMessage != null
                          ? Text(
                              _statusMessage!,
                              key: const ValueKey("status"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : const SizedBox.shrink()),
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
