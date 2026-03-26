import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/config/api_config.dart'; // Sesuaikan path ini

class DetailLaporanCepat extends StatefulWidget {
  final Map<String, dynamic> laporan;

  const DetailLaporanCepat({Key? key, required this.laporan}) : super(key: key);

  @override
  State<DetailLaporanCepat> createState() => _DetailLaporanCepatState();
}

class _DetailLaporanCepatState extends State<DetailLaporanCepat> {
  Uint8List? _fotoBytes;
  bool _loadingFoto = true;
  String? _fotoError;

  @override
  void initState() {
    super.initState();
    _fetchFoto();
  }

  // Mengambil foto dari backend berdasarkan id_laporan
  Future<void> _fetchFoto() async {
    final idLaporan = widget.laporan['id_laporan'];
    if (idLaporan == null) {
      setState(() {
        _loadingFoto = false;
        _fotoError = "ID Laporan tidak valid";
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      // ASUMSI ENDPOINT: /mobile/laporan-cepat/:id/foto
      // (Jika kamu belum punya endpoint ini di backend Node.js, kamu harus membuatnya ya)
      final url = Uri.parse('${ApiConfig.baseUrl}/mobile/laporan-cepat/$idLaporan/foto');
      
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _fotoBytes = res.bodyBytes;
          _loadingFoto = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _fotoError = "Tidak ada foto untuk laporan ini.";
          _loadingFoto = false;
        });
      } else {
        setState(() {
          _fotoError = "Gagal memuat foto (${res.statusCode})";
          _loadingFoto = false;
        });
      }
    } catch (e) {
      setState(() {
        _fotoError = "Terjadi kesalahan koneksi";
        _loadingFoto = false;
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
      final parts = tanggal.split('T')[0].split('-');
      if (parts.length != 3) return tanggal;
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    } catch (_) {
      return tanggal;
    }
  }

  String _formatWaktu(String? waktu) {
    if (waktu == null || waktu.isEmpty) return '-';
    final parts = waktu.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return waktu;
  }

  // Format created_at (Contoh: "2026-03-21T18:34:48.000Z") ke waktu lokal
  String _formatCreatedAt(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '-';
    try {
      DateTime parsed = DateTime.parse(createdAt).toLocal();
      return DateFormat('dd-MM-yyyy, HH:mm').format(parsed);
    } catch (_) {
      return '-';
    }
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(":", style: TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.laporan['status_validasi'] ?? 'pending').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== INFO LAPORAN ====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER: Judul & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.laporan['judul_laporan'] ?? 'Tanpa Judul',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(status),
                            ),
                          ),
                          backgroundColor: _statusColor(status).withOpacity(0.12),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),

                    // BODY: Tabel Info
                    Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FixedColumnWidth(16),
                        2: FlexColumnWidth(),
                      },
                      children: [
                        _buildTableRow(
                          "Dikirim pada", 
                          _formatCreatedAt(widget.laporan['created_at']?.toString())
                        ),
                        _buildTableRow(
                          "Tanggal Kejadian", 
                          _formatTanggal(widget.laporan['tanggal_kejadian']?.toString())
                        ),
                        _buildTableRow(
                          "Waktu Kejadian", 
                          _formatWaktu(widget.laporan['waktu_kejadian']?.toString())
                        ),
                        _buildTableRow(
                          "Koordinat", 
                          "${widget.laporan['latitude'] ?? '-'}, ${widget.laporan['longitude'] ?? '-'}"
                        ),
                        _buildTableRow(
                          "Deskripsi", 
                          widget.laporan['deskripsi']?.toString() ?? 'Tidak ada deskripsi'
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==== KOTAK FOTO ====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 12),
                    child: Text(
                      "Foto Bukti Laporan",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _loadingFoto
                        ? Row(
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text("Memuat foto..."),
                            ],
                          )
                        : _fotoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 4,
                                  child: Image.memory(
                                    _fotoBytes!,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _fotoError ?? "Foto tidak tersedia",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}