import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/lapor_cepat.dart/detail_laporan_cepat.dart';
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
    if (waktu == null || waktu.isEmpty) return '-';
    final parts = waktu.split(':'); // hh:mm:ss
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return waktu;
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Laporan Saya'),
        // backgroundColor: const Color(0xFF8B5A24),
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
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        item['judul_laporan'] ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Tanggal: ${_formatTanggal(item['tanggal_kejadian'] as String?)}'
                            '  •  Jam: ${_formatWaktu(item['waktu_kejadian'] as String?)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 4),
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
                        ],
                      ),
                      onTap: () {
                        // Mengirim data 'item' (Map) ke halaman Detail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailLaporanCepat(laporan: item),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
