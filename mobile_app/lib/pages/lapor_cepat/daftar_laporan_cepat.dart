import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_app/pages/lapor_cepat/detail_laporan_cepat.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/config/api_config.dart';

// SAMAKAN dengan baseUrl yang dipakai di LaporCepatPage
// const String apiBaseUrl = 'http://10.121.204.17:3000/api';

class DaftarLaporanPage extends StatefulWidget {
  const DaftarLaporanPage({Key? key}) : super(key: key);

  @override
  State<DaftarLaporanPage> createState() => _DaftarLaporanPageState();
}

class _DaftarLaporanPageState extends State<DaftarLaporanPage> {
  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _laporan = [];

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = "Token tidak ditemukan, silakan login ulang.";
          _loading = false;
        });
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/mobile/laporan-cepat/me');
      final res = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['data'] ?? [];

        setState(() {
          _laporan = list
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map),
              )
              .toList();
          _loading = false;
        });
      } else if (res.statusCode == 401) {
        setState(() {
          _errorMessage = "Sesi login kamu sudah habis, silakan login ulang.";
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data (status ${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'review':
      case 'in_review':
        return Colors.blue;
      case 'approved':
      case 'approve':
        return Colors.green;
      case 'rejected':
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    try {
      final parts = tanggal.split('-'); // yyyy-mm-dd
      if (parts.length != 3) return tanggal;
      final yyyy = parts[0];
      final mm = parts[1];
      final dd = parts[2];
      return '$dd-$mm-$yyyy';
    } catch (_) {
      return tanggal;
    }
  }

  String _formatWaktu(String? waktu) {
    if (waktu == null || waktu.trim().isEmpty) return '-';

    final value = waktu.trim();

    try {
      // Kalau format dari API mengandung Z / timezone, contoh:
      // 2026-06-29T12:32:56.000Z
      if (value.endsWith('Z') || value.contains('+')) {
        final dateTime = DateTime.parse(value).toLocal();

        final jam = dateTime.hour.toString().padLeft(2, '0');
        final menit = dateTime.minute.toString().padLeft(2, '0');

        return '$jam:$menit';
      }

      // Kalau format database biasa:
      // 2026-06-29 19:32:56
      final timePart = value.contains(' ')
          ? value.split(' ').last
          : value.contains('T')
          ? value.split('T').last
          : value;

      final parts = timePart.split(':');

      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }

      return value;
    } catch (_) {
      return value;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // Fungsi pengekstrak Jam

    // Fungsi pengekstrak Tanggal
    String _extractDate(String rawDate) {
      try {
        String cleanDate = rawDate.split(' ')[0];
        DateTime parsedDate = DateTime.parse(cleanDate).toLocal();
        // Pastikan package intl sudah di-import
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      } catch (e) {
        return "-";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Laporan Cepat Saya'),
        // backgroundColor: const Color(0xFF8B5A24),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLaporan,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _fetchLaporan,
                    child: const Text('Coba lagi'),
                  ),
                ],
              )
            : _laporan.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text(
                    'Kamu belum pernah mengirim laporan.\n'
                    'Gunakan menu "Lapor Cepat" untuk mengirim laporan pertama.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _laporan.length,
                itemBuilder: (context, index) {
                  final item = _laporan[index];
                  final status = (item['status_validasi'] ?? 'pending')
                      .toString();

                  return Card(
                    color: AppColors.borderSoft,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailLaporanCepat(laporan: item),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['judul_laporan'] ?? '-',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      Text(
                                        _formatWaktu(
                                          item['waktu_kejadian'] as String? ??
                                              '-',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "/",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _extractDate(
                                          item['tanggal_kejadian'] as String? ??
                                              '-',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        status,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            _LaporanThumbnail(idLaporan: item['id_laporan']),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _LaporanThumbnail extends StatefulWidget {
  final dynamic idLaporan;

  const _LaporanThumbnail({Key? key, required this.idLaporan})
    : super(key: key);

  @override
  State<_LaporanThumbnail> createState() => _LaporanThumbnailState();
}

class _LaporanThumbnailState extends State<_LaporanThumbnail> {
  Uint8List? _fotoBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFoto();
  }

  Future<void> _fetchFoto() async {
    final id = widget.idLaporan;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = "ID tidak valid";
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/mobile/laporan-cepat/$id/foto',
      );

      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _fotoBytes = res.bodyBytes;
          _loading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _error = "Foto tidak ada";
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Gagal load";
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Error";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        height: 88,
        color: Colors.grey.shade200,
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _fotoBytes != null
            ? Image.memory(
                _fotoBytes!,
                fit: BoxFit.cover,
                width: 88,
                height: 88,
              )
            : Center(
                child: Text(
                  _error ?? "No Foto",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
      ),
    );
  }
}
