import 'package:flutter/material.dart';
import 'package:mobile_app/services/police_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfficerFieldReportDetailPage extends StatefulWidget {
  final int reportId;
  final String reportTitle;

  const OfficerFieldReportDetailPage({
    super.key,
    required this.reportId,
    required this.reportTitle,
  });

  @override
  State<OfficerFieldReportDetailPage> createState() =>
      _OfficerFieldReportDetailPageState();
}

class _OfficerFieldReportDetailPageState
    extends State<OfficerFieldReportDetailPage> {
  bool _loading = true;
  bool _acting = false;
  Map<String, dynamic>? _data;
  int? _myId;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _s(dynamic v) {
    if (v == null) return '-';
    final t = v.toString().trim();
    return t.isEmpty ? '-' : t;
  }

  // Helper untuk warna status
  Map<String, dynamic> _statusProps(String s) {
    switch (s) {
      case 'pending':
        return {'text': 'Menunggu', 'color': Colors.orange};
      case 'on_process':
        return {'text': 'Diproses', 'color': Colors.blue};
      case 'selesai':
        return {'text': 'Selesai', 'color': Colors.green};
      case 'dibatalkan':
        return {'text': 'Dibatalkan', 'color': Colors.red};
      default:
        return {'text': s.toUpperCase(), 'color': Colors.grey};
    }
  }

  // Format Key-Value yang lebih rapi
  Widget _kv(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              _s(value),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format Section Card dengan Ikon
  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF1E3A8A)), // Biru Navy
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Colors.black12),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _myId = prefs.getInt('user_id');

      final d = await PoliceReportService.fetchOfficerDetail(widget.reportId);
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      _snack("❌ $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond() async {
    setState(() => _acting = true);
    try {
      await PoliceReportService.respond(widget.reportId);
      await _load();
      _snack("✅ Berhasil diambil. Status -> Diproses");
    } catch (e) {
      _snack("❌ $e");
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _acting = true);
    try {
      await PoliceReportService.finish(widget.reportId);
      await _load();
      _snack("✅ Selesai. Status -> Selesai");
    } catch (e) {
      _snack("❌ $e");
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final statusStr = _s(d?['status'] ?? 'pending');
    final statusProps = _statusProps(statusStr);
    final assignedOfficer = d?['assigned_officer_user_id'];

    final isMine = (_myId != null &&
        assignedOfficer != null &&
        assignedOfficer.toString() == _myId.toString());

    final canRespond = statusStr == 'pending' && assignedOfficer == null;
    final canComplete = statusStr == 'on_process' && isMine;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Detail Tindak Pidana: ${widget.reportTitle}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? const Center(child: Text("Data tidak ditemukan."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- HEADER INFO (Status & Judul) ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.reportTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusProps['color'].withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusProps['text'],
                                    style: TextStyle(
                                      color: statusProps['color'],
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _kv("Dibuat Pada", d['created_at']),
                            _kv("Update Terakhir", d['updated_at']),
                            _kv("Petugas Menangani", assignedOfficer ?? "Belum ada"),
                            if (_s(d['catatan_admin']) != '-')
                              _kv("Catatan Admin", d['catatan_admin']),
                          ],
                        ),
                      ),

                      // --- SECTIONS ---
                      _section("Waktu & Tempat Kejadian", Icons.location_on, [
                        _kv("Hari, Tanggal", "${_s(d['waktu_kejadian_hari'])}, ${_s(d['waktu_kejadian_tanggal'])}"),
                        _kv("Jam", d['waktu_kejadian_jam']),
                        const SizedBox(height: 8),
                        _kv("Jalan", d['tempat_jalan']),
                        _kv("Desa/Kelurahan", d['tempat_desa_kel']),
                        _kv("Kecamatan", d['tempat_kecamatan']),
                        _kv("Kabupaten/Kota", d['tempat_kab_kota']),
                      ]),

                      _section("Detail Peristiwa", Icons.warning_amber_rounded, [
                        _kv("Tindak Pidana", d['tindak_pidana']),
                        _kv("Apa yang terjadi", d['apa_terjadi']),
                        _kv("Bagaimana terjadi", d['bagaimana_terjadi']),
                        _kv("Barang Bukti", d['barang_bukti']),
                        _kv("Uraian Singkat", d['uraian_singkat']),
                        _kv("Tindakan", d['tindakan_dilakukan']),
                      ]),

                      _section("Data Terlapor", Icons.person_off, [
                        _kv("Nama", d['terlapor_nama']),
                        _kv("Jenis Kelamin", d['terlapor_jk']),
                        _kv("Pekerjaan", d['terlapor_pekerjaan']),
                        _kv("Kontak", d['terlapor_kontak']),
                        _kv("Alamat", d['terlapor_alamat']),
                      ]),

                      _section("Data Korban", Icons.person, [
                        _kv("Nama", d['korban_nama']),
                        _kv("Jenis Kelamin", d['korban_jk']),
                        _kv("Pekerjaan", d['korban_pekerjaan']),
                        _kv("Kontak", d['korban_kontak']),
                        _kv("Alamat", d['korban_alamat']),
                      ]),

                      _section("Data Saksi 1", Icons.group, [
                        _kv("Nama", d['saksi1_nama']),
                        _kv("Umur", d['saksi1_umur']),
                        _kv("Pekerjaan", d['saksi1_pekerjaan']),
                        _kv("Alamat", d['saksi1_alamat']),
                      ]),

                      if (_s(d['saksi2_nama']) != '-')
                        _section("Data Saksi 2", Icons.group, [
                          _kv("Nama", d['saksi2_nama']),
                          _kv("Umur", d['saksi2_umur']),
                          _kv("Pekerjaan", d['saksi2_pekerjaan']),
                          _kv("Alamat", d['saksi2_alamat']),
                        ]),

                      _section("Mengetahui & Petugas", Icons.local_police, [
                        _kv("Jabatan Kepala", d['mengetahui_kepala_jabatan']),
                        _kv("Nama Kepala", d['mengetahui_kepala_nama']),
                        _kv("Pangkat/NRP", d['mengetahui_kepala_pangkat_nrp']),
                        const Divider(height: 20),
                        _kv("Nama Pelapor (Petugas)", d['pelapor_nama']),
                        _kv("Pangkat/NRP Pelapor", d['pelapor_pangkat_nrp']),
                        _kv("Kesatuan", d['pelapor_kesatuan']),
                        _kv("Kontak Pelapor", d['pelapor_kontak']),
                      ]),

                      const SizedBox(height: 16),

                      // --- ACTION BUTTONS ---
                      if (canRespond)
                        ElevatedButton.icon(
                          onPressed: _acting ? null : _respond,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.handshake),
                          label: _acting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "AMBIL & PROSES LAPORAN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),

                      if (!canRespond && statusStr == 'pending' && assignedOfficer != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Laporan ini sudah diambil oleh petugas lain.",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (canComplete)
                        ElevatedButton.icon(
                          onPressed: _acting ? null : _complete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: _acting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "TANDAI SELESAI",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                        
                      const SizedBox(height: 40), // Padding bawah tambahan
                    ],
                  ),
                ),
    );
  }
}