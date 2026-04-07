// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mobile_app/theme/app_theme.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:typed_data';
// import 'package:mobile_app/services/profile_service.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   bool _loading = true;
//   bool _saving = false;
//   bool _edit = false;

//   Map<String, dynamic>? _me;

//   final _formKey = GlobalKey<FormState>();

//   // controllers
//   final _nik = TextEditingController();
//   final _nama = TextEditingController();
//   final _tempatLahir = TextEditingController();
//   final _tanggalLahir = TextEditingController();
//   final _alamat = TextEditingController();
//   final _phone = TextEditingController();
//   final _email = TextEditingController();
//   final _username = TextEditingController();

//   void _snack(String m) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

//   String _s(dynamic v) {
//     if (v == null) return "-";
//     final t = v.toString().trim();
//     return t.isEmpty ? "-" : t;
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadMe();
//   }

//   @override
//   void dispose() {
//     _nik.dispose();
//     _nama.dispose();
//     _tempatLahir.dispose();
//     _tanggalLahir.dispose();
//     _alamat.dispose();
//     _phone.dispose();
//     _email.dispose();
//     _username.dispose();
//     super.dispose();
//   }

//   Future<void> _loadMe() async {
//     setState(() => _loading = true);
//     try {
//       final me = await ProfileService.getMe();
//       _me = me;

//       // set form
//       _nik.text = (me['nik'] ?? '').toString();
//       _nama.text = (me['nama'] ?? '').toString();
//       _tempatLahir.text = (me['tempat_lahir'] ?? '').toString();
//       _tanggalLahir.text = (me['tanggal_lahir'] ?? '').toString();
//       _alamat.text = (me['alamat'] ?? '').toString();
//       _phone.text = (me['phone'] ?? '').toString();
//       _email.text = (me['email'] ?? '').toString();
//       _username.text = (me['username'] ?? '').toString();

//       // sync sharedprefs status_verifikasi biar konsisten di app lain
//       final prefs = await SharedPreferences.getInstance();
//       final status = (me['status_verifikasi'] ?? 'pending').toString();
//       await prefs.setString('status_verifikasi', status);
//     } catch (e) {
//       _snack(" $e");
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'verified':
//         return Colors.green;
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.orange;
//     }
//   }

//   String _statusLabel(String status) {
//     switch (status) {
//       case 'verified':
//         return "VERIFIED ";
//       case 'rejected':
//         return "REJECTED ";
//       default:
//         return "PENDING ⏳";
//     }
//   }

//   Future<void> _pickTanggalLahir() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: DateTime(1900),
//       lastDate: now,
//     );
//     if (picked == null) return;

//     final yyyy = picked.year.toString().padLeft(4, '0');
//     final mm = picked.month.toString().padLeft(2, '0');
//     final dd = picked.day.toString().padLeft(2, '0');
//     setState(() => _tanggalLahir.text = "$yyyy-$mm-$dd");
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _saving = true);
//     try {
//       final payload = <String, dynamic>{
//         "nik": _nik.text.trim(),
//         "nama": _nama.text.trim(),
//         "tempat_lahir": _tempatLahir.text.trim(),
//         "tanggal_lahir": _tanggalLahir.text.trim(),
//         "alamat": _alamat.text.trim(),
//         "phone": _phone.text.trim(),
//         "email": _email.text.trim(),
//         "username": _username.text.trim(),
//       };

//       // kosong => null
//       payload.removeWhere((k, v) => v is String && v.trim().isEmpty);

//       final updated = await ProfileService.updateMe(payload);

//       setState(() {
//         _me = updated['data'] ?? _me; // kalau backend return {data:...}
//         _edit = false;
//       });

//       await _loadMe();
//       _snack(" Profil ke-update");
//     } catch (e) {
//       _snack(" $e");
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _resubmitKtp() async {
//     final status = (_me?['status_verifikasi'] ?? 'pending').toString();
//     if (status != 'rejected') {
//       _snack("KTP hanya bisa dikirim ulang kalau status kamu REJECTED.");
//       return;
//     }

//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Kirim ulang KTP?"),
//         content: const Text("Pastikan foto KTP jelas dan tidak blur ya."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Batal"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Lanjut"),
//           ),
//         ],
//       ),
//     );

//     if (ok != true) return;

//     final picker = ImagePicker();
//     final picked = await picker.pickImage(
//       source: ImageSource.gallery, // bisa ganti camera kalau mau
//       imageQuality: 85,
//     );
//     if (picked == null) return;

//     setState(() => _saving = true);
//     try {
//       await ProfileService.resubmitKtp(File(picked.path));
//       await _loadMe();
//       _snack("✅ KTP terkirim ulang. Status jadi PENDING lagi.");
//     } catch (e) {
//       _snack(" $e");
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _previewKtp() async {
//     try {
//       final bytes = await ProfileService.getMyKtpBytes(); // ini masih List<int>
//       if (!mounted) return;

//       final u8 = Uint8List.fromList(bytes); // ✅ convert ke Uint8List
//       Image.memory(u8);

//       showDialog(
//         context: context,
//         builder: (_) => Dialog(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 child: const Text(
//                   "Preview KTP",
//                   style: TextStyle(fontWeight: FontWeight.w800),
//                 ),
//               ),
//               Flexible(
//                 child: InteractiveViewer(
//                   child: Image.memory(u8, fit: BoxFit.contain), // ✅ pake u8
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Tutup"),
//               ),
//             ],
//           ),
//         ),
//       );
//     } catch (e) {
//       _snack(" $e");
//     }
//   }

//   InputDecoration _dec(String label) => InputDecoration(
//     labelText: label,
//     filled: true,
//     fillColor: Colors.white,
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(14),
//       borderSide: BorderSide.none,
//     ),
//   );

//   Widget _field(
//     TextEditingController c, {
//     required String label,
//     bool required = false,
//     bool enabled = true,
//     int maxLines = 1,
//     TextInputType? keyboardType,
//     VoidCallback? onTapReadOnly,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: TextFormField(
//         controller: c,
//         enabled: enabled,
//         readOnly: onTapReadOnly != null,
//         onTap: onTapReadOnly,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         validator: required
//             ? (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null
//             : null,
//         decoration: _dec(label),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final me = _me;
//     final role = (me?['role'] ?? '-').toString();
//     final status = (me?['status_verifikasi'] ?? 'pending').toString();
//     final catatan = (me?['catatan_verifikasi'] ?? '').toString();

//     final canResubmit = status == 'rejected';

//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F4F4),
//       appBar: AppBar(
//         title: const Text("Profil Saya"),
//         backgroundColor: isDark ? AppColors.bgPrimary : const Color(0xFFF4F4F4),
//         actions: [
//           IconButton(
//             onPressed: _loading ? null : _loadMe,
//             icon: const Icon(Icons.refresh),
//             // style: ButtonStyle(
//             //   iconColor: WidgetStatePropertyAll<Color>(Colors.white),
//             // ),
//           ),
//           IconButton(
//             onPressed: _loading ? null : () => setState(() => _edit = !_edit),
//             icon: Icon(_edit ? Icons.close : Icons.edit),
//             // style: ButtonStyle(
//             //   iconColor: WidgetStatePropertyAll<Color>(Colors.white),
//             // ),
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : me == null
//           ? const Center(child: Text("Profil tidak ditemukan"))
//           : Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // ===== STATUS CARD =====
//                     Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(18),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(14),
//                         child: Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: _statusColor(status).withOpacity(0.15),
//                                 borderRadius: BorderRadius.circular(999),
//                                 border: Border.all(
//                                   color: _statusColor(status),
//                                   width: 1,
//                                 ),
//                               ),
//                               child: Text(
//                                 _statusLabel(status),
//                                 style: TextStyle(
//                                   color: _statusColor(status),
//                                   fontWeight: FontWeight.w900,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 "Role: $role",
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               onPressed: _previewKtp,
//                               icon: const Icon(Icons.badge_outlined),
//                               tooltip: "Lihat KTP",
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     if (catatan.trim().isNotEmpty) ...[
//                       const SizedBox(height: 10),
//                       Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(18),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(14),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Icon(Icons.info_outline, size: 18),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: Text(
//                                   "Catatan verifikasi:\n$catatan",
//                                   style: const TextStyle(height: 1.3),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],

//                     const SizedBox(height: 14),

//                     // ===== FORM =====
//                     Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(18),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(6),
//                         child: Column(
//                           children: [
//                             _field(
//                               _nik,
//                               label: "NIK",
//                               required: true,
//                               enabled: _edit,
//                             ),
//                             _field(
//                               _nama,
//                               label: "Nama",
//                               required: true,
//                               enabled: _edit,
//                             ),
//                             _field(
//                               _username,
//                               label: "Username",
//                               required: true,
//                               enabled: _edit,
//                             ),
//                             _field(
//                               _tempatLahir,
//                               label: "Tempat lahir",
//                               enabled: _edit,
//                             ),
//                             _field(
//                               _tanggalLahir,
//                               label: "Tanggal lahir (YYYY-MM-DD)",
//                               enabled: _edit,
//                               onTapReadOnly: _edit ? _pickTanggalLahir : null,
//                             ),
//                             _field(
//                               _alamat,
//                               label: "Alamat",
//                               enabled: _edit,
//                               maxLines: 3,
//                             ),
//                             _field(
//                               _phone,
//                               label: "Phone",
//                               enabled: _edit,
//                               keyboardType: TextInputType.phone,
//                             ),
//                             _field(
//                               _email,
//                               label: "Email",
//                               enabled: _edit,
//                               keyboardType: TextInputType.emailAddress,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     if (_edit)
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _saving ? null : _save,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF8B5A24),
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           icon: _saving
//                               ? const SizedBox(
//                                   height: 18,
//                                   width: 18,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                               : const Icon(Icons.save, color: Colors.white),
//                           label: Text(
//                             _saving ? "Menyimpan..." : "SIMPAN",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w900,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: 10),

//                     if (canResubmit)
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _saving ? null : _resubmitKtp,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           icon: const Icon(Icons.upload, color: Colors.white),
//                           label: const Text(
//                             "KIRIM ULANG FOTO KTP",
//                             style: TextStyle(fontWeight: FontWeight.w900),
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: 30),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mobile_app/theme/app_theme.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:typed_data';
// import 'package:mobile_app/services/profile_service.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   bool _loading = true;
//   bool _saving = false;
//   bool _edit = false;

//   Map<String, dynamic>? _me;

//   final _formKey = GlobalKey<FormState>();

//   // controllers
//   final _nik = TextEditingController();
//   final _nama = TextEditingController();
//   final _tempatLahir = TextEditingController();
//   final _tanggalLahir = TextEditingController();
//   final _alamat = TextEditingController();
//   final _phone = TextEditingController();
//   final _email = TextEditingController();
//   final _username = TextEditingController();

//   void _snack(String m) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

//   String _s(dynamic v) {
//     if (v == null) return "-";
//     final t = v.toString().trim();
//     return t.isEmpty ? "-" : t;
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadMe();
//   }

//   @override
//   void dispose() {
//     _nik.dispose();
//     _nama.dispose();
//     _tempatLahir.dispose();
//     _tanggalLahir.dispose();
//     _alamat.dispose();
//     _phone.dispose();
//     _email.dispose();
//     _username.dispose();
//     super.dispose();
//   }

//   Future<void> _loadMe() async {
//     setState(() => _loading = true);
//     try {
//       final me = await ProfileService.getMe();
//       _me = me;

//       // set form
//       _nik.text = (me['nik'] ?? '').toString();
//       _nama.text = (me['nama'] ?? '').toString();
//       _tempatLahir.text = (me['tempat_lahir'] ?? '').toString();
//       _tanggalLahir.text = (me['tanggal_lahir'] ?? '').toString();
//       _alamat.text = (me['alamat'] ?? '').toString();
//       _phone.text = (me['phone'] ?? '').toString();
//       _email.text = (me['email'] ?? '').toString();
//       _username.text = (me['username'] ?? '').toString();

//       // sync sharedprefs status_verifikasi biar konsisten di app lain
//       final prefs = await SharedPreferences.getInstance();
//       final status = (me['status_verifikasi'] ?? 'pending').toString();
//       await prefs.setString('status_verifikasi', status);
//     } catch (e) {
//       _snack(" $e");
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'verified':
//         return Colors.green.shade600;
//       case 'rejected':
//         return Colors.red.shade600;
//       default:
//         return Colors.orange.shade600;
//     }
//   }

//   String _statusLabel(String status) {
//     switch (status.toLowerCase()) {
//       case 'verified':
//         return "VERIFIED";
//       case 'rejected':
//         return "REJECTED";
//       default:
//         return "PENDING ⏳";
//     }
//   }

//   Future<void> _pickTanggalLahir() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: DateTime(1900),
//       lastDate: now,
//     );
//     if (picked == null) return;

//     final yyyy = picked.year.toString().padLeft(4, '0');
//     final mm = picked.month.toString().padLeft(2, '0');
//     final dd = picked.day.toString().padLeft(4, '0');
//     setState(() => _tanggalLahir.text = "$yyyy-$mm-$dd");
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _saving = true);
//     try {
//       final payload = <String, dynamic>{
//         "nik": _nik.text.trim(),
//         "nama": _nama.text.trim(),
//         "tempat_lahir": _tempatLahir.text.trim(),
//         "tanggal_lahir": _tanggalLahir.text.trim(),
//         "alamat": _alamat.text.trim(),
//         "phone": _phone.text.trim(),
//         "email": _email.text.trim(),
//         "username": _username.text.trim(),
//       };

//       // kosong => null
//       payload.removeWhere((k, v) => v is String && v.trim().isEmpty);

//       final updated = await ProfileService.updateMe(payload);

//       setState(() {
//         _me = updated['data'] ?? _me; // kalau backend return {data:...}
//         _edit = false;
//       });

//       await _loadMe();
//       _snack("✅ Profil berhasil diperbarui");
//     } catch (e) {
//       _snack(" $e");
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _resubmitKtp() async {
//     final status = (_me?['status_verifikasi'] ?? 'pending').toString();
//     if (status != 'rejected') {
//       _snack("KTP hanya bisa dikirim ulang kalau status kamu REJECTED.");
//       return;
//     }

//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Kirim ulang KTP?"),
//         content: const Text("Pastikan foto KTP jelas dan tidak blur ya."),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Batal"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: const Text("Lanjut"),
//           ),
//         ],
//       ),
//     );

//     if (ok != true) return;

//     final picker = ImagePicker();
//     final picked = await picker.pickImage(
//       source: ImageSource.gallery, // bisa ganti camera kalau mau
//       imageQuality: 85,
//     );
//     if (picked == null) return;

//     setState(() => _saving = true);
//     try {
//       await ProfileService.resubmitKtp(File(picked.path));
//       await _loadMe();
//       _snack("✅ KTP terkirim ulang. Status jadi PENDING lagi.");
//     } catch (e) {
//       _snack(" $e");
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _previewKtp() async {
//     try {
//       final bytes = await ProfileService.getMyKtpBytes();
//       if (!mounted) return;

//       final u8 = Uint8List.fromList(bytes);

//       showDialog(
//         context: context,
//         builder: (_) => Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 child: const Text(
//                   "Preview KTP",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                 ),
//               ),
//               Flexible(
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: InteractiveViewer(
//                     child: Image.memory(u8, fit: BoxFit.contain),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Tutup"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     } catch (e) {
//       _snack(" $e");
//     }
//   }

//   // Desain baru untuk field form
//   InputDecoration _dec(String label, IconData icon, bool enabled) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(
//         icon,
//         size: 20,
//         color: enabled ? colorScheme.primary : Colors.grey,
//       ),
//       filled: true,
//       fillColor: enabled
//           ? (isDark ? Colors.grey.shade900 : Colors.white)
//           : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
//       contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(
//           color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
//         ),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(color: colorScheme.primary, width: 2),
//       ),
//       disabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(
//           color: isDark ? Colors.transparent : Colors.grey.shade200,
//         ),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(color: colorScheme.error),
//       ),
//     );
//   }

//   Widget _field(
//     TextEditingController c, {
//     required String label,
//     required IconData icon,
//     bool required = false,
//     bool enabled = true,
//     int maxLines = 1,
//     TextInputType? keyboardType,
//     VoidCallback? onTapReadOnly,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: TextFormField(
//         controller: c,
//         enabled: enabled,
//         readOnly: onTapReadOnly != null,
//         onTap: onTapReadOnly,
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         style: TextStyle(
//           color: enabled
//               ? Theme.of(context).textTheme.bodyLarge?.color
//               : Colors.grey.shade600,
//         ),
//         validator: required
//             ? (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null
//             : null,
//         decoration: _dec(label, icon, enabled),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     final me = _me;
//     final role = (me?['role'] ?? '-').toString().toUpperCase();
//     final status = (me?['status_verifikasi'] ?? 'pending').toString();
//     final catatan = (me?['catatan_verifikasi'] ?? '').toString();
//     final namaUser = _nama.text.isNotEmpty ? _nama.text : 'User';

//     final canResubmit = status == 'rejected';

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text("Profil Saya"),
//         centerTitle: true,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         actions: [
//           IconButton(
//             onPressed: _loading ? null : _loadMe,
//             icon: const Icon(Icons.refresh),
//             tooltip: "Muat Ulang",
//           ),
//           IconButton(
//             onPressed: _loading ? null : () => setState(() => _edit = !_edit),
//             icon: Icon(_edit ? Icons.close : Icons.edit_note),
//             tooltip: _edit ? "Batal Edit" : "Edit Profil",
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : me == null
//           ? const Center(child: Text("Profil tidak ditemukan"))
//           : Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 24,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // ===== HEADER AVATAR =====
//                     CircleAvatar(
//                       radius: 46,
//                       backgroundColor: theme.colorScheme.primary.withOpacity(
//                         0.1,
//                       ),
//                       child: Text(
//                         namaUser.isNotEmpty ? namaUser[0].toUpperCase() : '?',
//                         style: TextStyle(
//                           fontSize: 36,
//                           fontWeight: FontWeight.bold,
//                           color: theme.colorScheme.primary,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       namaUser,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       "@${_username.text}",
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // ===== STATUS CARD =====
//                     Container(
//                       decoration: BoxDecoration(
//                         color: isDark ? Colors.grey.shade900 : Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.04),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 14,
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 14,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _statusColor(status).withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(999),
//                               border: Border.all(
//                                 color: _statusColor(status).withOpacity(0.5),
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   status.toLowerCase() == 'verified'
//                                       ? Icons.verified
//                                       : (status.toLowerCase() == 'rejected'
//                                             ? Icons.cancel
//                                             : Icons.pending),
//                                   size: 16,
//                                   color: _statusColor(status),
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   _statusLabel(status),
//                                   style: TextStyle(
//                                     color: _statusColor(status),
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const Spacer(),
//                           Text(
//                             role,
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: theme.colorScheme.primary,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             height: 24,
//                             width: 1,
//                             color: Colors.grey.shade300,
//                           ),
//                           IconButton(
//                             onPressed: _previewKtp,
//                             icon: const Icon(Icons.badge_outlined),
//                             tooltip: "Lihat KTP",
//                             color: theme.colorScheme.primary,
//                             constraints: const BoxConstraints(),
//                             padding: const EdgeInsets.only(left: 12),
//                           ),
//                         ],
//                       ),
//                     ),

//                     if (catatan.trim().isNotEmpty) ...[
//                       const SizedBox(height: 12),
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: Colors.orange.shade300),
//                         ),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(
//                               Icons.info_outline,
//                               size: 20,
//                               color: Colors.orange.shade800,
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Text(
//                                 "Catatan Verifikasi:\n$catatan",
//                                 style: TextStyle(
//                                   height: 1.4,
//                                   color: Colors.orange.shade900,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],

//                     const SizedBox(height: 32),

//                     // Header Form
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         "Informasi Pribadi",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isDark
//                               ? Colors.grey.shade300
//                               : Colors.grey.shade800,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // ===== FORM =====
//                     _field(
//                       _nik,
//                       label: "Nomor Induk Kependudukan (NIK)",
//                       icon: Icons.credit_card,
//                       required: true,
//                       enabled: _edit,
//                       keyboardType: TextInputType.number,
//                     ),
//                     _field(
//                       _nama,
//                       label: "Nama Lengkap",
//                       icon: Icons.person_outline,
//                       required: true,
//                       enabled: _edit,
//                     ),
//                     _field(
//                       _username,
//                       label: "Username",
//                       icon: Icons.alternate_email,
//                       required: true,
//                       enabled: _edit,
//                     ),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _field(
//                             _tempatLahir,
//                             label: "Tempat Lahir",
//                             icon: Icons.location_city,
//                             enabled: _edit,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _field(
//                             _tanggalLahir,
//                             label: "Tanggal Lahir",
//                             icon: Icons.calendar_today,
//                             enabled: _edit,
//                             onTapReadOnly: _edit ? _pickTanggalLahir : null,
//                           ),
//                         ),
//                       ],
//                     ),
//                     _field(
//                       _alamat,
//                       label: "Alamat Lengkap",
//                       icon: Icons.home_outlined,
//                       enabled: _edit,
//                       maxLines: 3,
//                     ),
//                     _field(
//                       _phone,
//                       label: "Nomor Telepon",
//                       icon: Icons.phone_outlined,
//                       enabled: _edit,
//                       keyboardType: TextInputType.phone,
//                     ),
//                     _field(
//                       _email,
//                       label: "Email",
//                       icon: Icons.email_outlined,
//                       enabled: _edit,
//                       keyboardType: TextInputType.emailAddress,
//                     ),

//                     const SizedBox(height: 16),

//                     // ===== TOMBOL AKSI =====
//                     if (_edit)
//                       SizedBox(
//                         width: double.infinity,
//                         height: 54,
//                         child: ElevatedButton.icon(
//                           onPressed: _saving ? null : _save,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF8B5A24),
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           icon: _saving
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2.5,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                               : const Icon(Icons.save_rounded),
//                           label: Text(
//                             _saving ? "MENYIMPAN..." : "SIMPAN PROFIL",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 1,
//                             ),
//                           ),
//                         ),
//                       ),

//                     if (canResubmit && !_edit)
//                       SizedBox(
//                         width: double.infinity,
//                         height: 54,
//                         child: ElevatedButton.icon(
//                           onPressed: _saving ? null : _resubmitKtp,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red.shade600,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           icon: const Icon(Icons.upload_file),
//                           label: const Text(
//                             "KIRIM ULANG FOTO KTP",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 1,
//                             ),
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:mobile_app/services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  bool _saving = false;
  bool _edit = false;

  Map<String, dynamic>? _me;

  final _formKey = GlobalKey<FormState>();

  // controllers
  final _nik = TextEditingController();
  final _nama = TextEditingController();
  final _tempatLahir = TextEditingController();
  final _tanggalLahir = TextEditingController();
  final _alamat = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _s(dynamic v) {
    if (v == null) return "-";
    final t = v.toString().trim();
    return t.isEmpty ? "-" : t;
  }

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  @override
  void dispose() {
    _nik.dispose();
    _nama.dispose();
    _tempatLahir.dispose();
    _tanggalLahir.dispose();
    _alamat.dispose();
    _phone.dispose();
    _email.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    setState(() => _loading = true);
    try {
      final me = await ProfileService.getMe();
      _me = me;

      // set form
      _nik.text = (me['nik'] ?? '').toString();
      _nama.text = (me['nama'] ?? '').toString();
      _tempatLahir.text = (me['tempat_lahir'] ?? '').toString();
      _tanggalLahir.text = (me['tanggal_lahir'] ?? '').toString();
      _alamat.text = (me['alamat'] ?? '').toString();
      _phone.text = (me['phone'] ?? '').toString();
      _email.text = (me['email'] ?? '').toString();
      _username.text = (me['username'] ?? '').toString();

      // sync sharedprefs status_verifikasi biar konsisten di app lain
      final prefs = await SharedPreferences.getInstance();
      final status = (me['status_verifikasi'] ?? 'pending').toString();
      await prefs.setString('status_verifikasi', status);
    } catch (e) {
      _snack(" $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.orange.shade600;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return "VERIFIED";
      case 'rejected':
        return "REJECTED";
      default:
        return "PENDING ⏳";
    }
  }

  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;

    final yyyy = picked.year.toString().padLeft(4, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');
    setState(() => _tanggalLahir.text = "$yyyy-$mm-$dd");
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        "nik": _nik.text.trim(),
        "nama": _nama.text.trim(),
        "tempat_lahir": _tempatLahir.text.trim(),
        "tanggal_lahir": _tanggalLahir.text.trim(),
        "alamat": _alamat.text.trim(),
        "phone": _phone.text.trim(),
        "email": _email.text.trim(),
        "username": _username.text.trim(),
      };

      // kosong => null
      payload.removeWhere((k, v) => v is String && v.trim().isEmpty);

      final updated = await ProfileService.updateMe(payload);

      setState(() {
        _me = updated['data'] ?? _me; // kalau backend return {data:...}
        _edit = false;
      });

      await _loadMe();
      _snack("✅ Profil berhasil diperbarui");
    } catch (e) {
      _snack(" $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resubmitKtp() async {
    final status = (_me?['status_verifikasi'] ?? 'pending').toString();
    if (status != 'rejected') {
      _snack("KTP hanya bisa dikirim ulang kalau status kamu REJECTED.");
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kirim ulang KTP?"),
        content: const Text("Pastikan foto KTP jelas dan tidak blur ya."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Lanjut"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      await ProfileService.resubmitKtp(File(picked.path));
      await _loadMe();
      _snack("✅ KTP terkirim ulang. Status jadi PENDING lagi.");
    } catch (e) {
      _snack(" $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _previewKtp() async {
    try {
      final bytes = await ProfileService.getMyKtpBytes();
      if (!mounted) return;

      final u8 = Uint8List.fromList(bytes);

      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  "Preview KTP",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveViewer(
                    child: Image.memory(u8, fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _snack(" $e");
    }
  }

  // Label text dihapus dari sini, diganti jadi hintText
  InputDecoration _dec(String hint, IconData icon, bool enabled) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: enabled ? colorScheme.primary : Colors.grey,
      ),
      filled: true,
      fillColor: enabled
          ? (isDark ? Colors.grey.shade900 : Colors.white)
          : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }

  // Widget builder diubah menggunakan Column untuk menaruh label di atas
  Widget _field(
    TextEditingController c, {
    required String label,
    String? hint,
    required IconData icon,
    bool required = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onTapReadOnly,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 20,
      ), // Sedikit ekstra ruang antar field
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label ditempatkan di atas field
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              required ? "$label *" : label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600, // Semi-bold agar jelas
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
          TextFormField(
            controller: c,
            enabled: enabled,
            readOnly: onTapReadOnly != null,
            onTap: onTapReadOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(
              color: enabled
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Colors.grey.shade600,
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null
                : null,
            decoration: _dec(hint ?? "Ketik $label...", icon, enabled),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final me = _me;
    final role = (me?['role'] ?? '-').toString().toUpperCase();
    final status = (me?['status_verifikasi'] ?? 'pending').toString();
    final catatan = (me?['catatan_verifikasi'] ?? '').toString();
    final namaUser = _nama.text.isNotEmpty ? _nama.text : 'User';

    final canResubmit = status == 'rejected';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profil Saya"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadMe,
            icon: const Icon(Icons.refresh),
            tooltip: "Muat Ulang",
          ),
          IconButton(
            onPressed: _loading ? null : () => setState(() => _edit = !_edit),
            icon: Icon(_edit ? Icons.close : Icons.edit_note),
            tooltip: _edit ? "Batal Edit" : "Edit Profil",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : me == null
          ? const Center(child: Text("Profil tidak ditemukan"))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ===== HEADER AVATAR =====
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      child: Text(
                        namaUser.isNotEmpty ? namaUser[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      namaUser,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "@${_username.text}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== STATUS CARD =====
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _statusColor(status).withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  status.toLowerCase() == 'verified'
                                      ? Icons.verified
                                      : (status.toLowerCase() == 'rejected'
                                            ? Icons.cancel
                                            : Icons.pending),
                                  size: 16,
                                  color: _statusColor(status),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            role,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 24,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          IconButton(
                            onPressed: _previewKtp,
                            icon: const Icon(Icons.badge_outlined),
                            tooltip: "Lihat KTP",
                            color: theme.colorScheme.primary,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 12),
                          ),
                        ],
                      ),
                    ),

                    if (catatan.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Catatan Verifikasi:\n$catatan",
                                style: TextStyle(
                                  height: 1.4,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Header Form
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Informasi Pribadi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey.shade100
                              : Colors.grey.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== FORM =====
                    _field(
                      _nik,
                      label: "Nomor Induk Kependudukan (NIK)",
                      hint: "Masukkan NIK",
                      icon: Icons.credit_card,
                      required: true,
                      enabled: _edit,
                      keyboardType: TextInputType.number,
                    ),
                    _field(
                      _nama,
                      label: "Nama Lengkap",
                      hint: "Sesuai KTP",
                      icon: Icons.person_outline,
                      required: true,
                      enabled: _edit,
                    ),
                    _field(
                      _username,
                      label: "Username",
                      hint: "Masukkan username unik",
                      icon: Icons.alternate_email,
                      required: true,
                      enabled: _edit,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _tempatLahir,
                            label: "Tempat Lahir",
                            hint: "Kota kelahiran",
                            icon: Icons.location_city,
                            enabled: _edit,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _tanggalLahir,
                            label: "Tanggal Lahir",
                            hint: "YYYY-MM-DD",
                            icon: Icons.calendar_today,
                            enabled: _edit,
                            onTapReadOnly: _edit ? _pickTanggalLahir : null,
                          ),
                        ),
                      ],
                    ),
                    _field(
                      _alamat,
                      label: "Alamat Lengkap",
                      hint: "Tulis alamat rumah lengkap",
                      icon: Icons.home_outlined,
                      enabled: _edit,
                      maxLines: 3,
                    ),
                    _field(
                      _phone,
                      label: "Nomor Telepon",
                      hint: "Contoh: 0812...",
                      icon: Icons.phone_outlined,
                      enabled: _edit,
                      keyboardType: TextInputType.phone,
                    ),
                    _field(
                      _email,
                      label: "Alamat Email",
                      hint: "email@contoh.com",
                      icon: Icons.email_outlined,
                      enabled: _edit,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // ===== TOMBOL AKSI =====
                    if (_edit)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5A24),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _saving ? "MENYIMPAN..." : "SIMPAN PROFIL",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                    if (canResubmit && !_edit)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _resubmitKtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text(
                            "KIRIM ULANG FOTO KTP",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
