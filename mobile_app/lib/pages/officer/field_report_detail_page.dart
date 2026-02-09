import 'package:flutter/material.dart';
import 'package:mobile_app/services/police_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfficerFieldReportDetailPage extends StatefulWidget {
  final int reportId;
  const OfficerFieldReportDetailPage({super.key, required this.reportId});

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

  Widget _kv(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(_s(value))),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
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
      _snack("✅ Berhasil diambil. Status -> on_process");
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
      _snack("✅ Selesai. Status -> selesai");
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
    final status = _s(d?['status'] ?? 'pending');
    final assignedOfficer = d?['assigned_officer_user_id'];

    final isMine =
        (_myId != null &&
        assignedOfficer != null &&
        assignedOfficer.toString() == _myId.toString());

    final canRespond = status == 'pending' && assignedOfficer == null;
    final canComplete = status == 'on_process' && isMine;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: Text("Detail #${widget.reportId}"),
        backgroundColor: const Color(0xFF8B5A24),
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
                children: [
                  _section("Status", [
                    _kv("Status", status),
                    _kv("Assigned officer", assignedOfficer),
                    _kv("Catatan admin", d['catatan_admin']),
                    _kv("Created", d['created_at']),
                    _kv("Updated", d['updated_at']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Waktu & Tempat Kejadian", [
                    _kv("Hari", d['waktu_kejadian_hari']),
                    _kv("Tanggal", d['waktu_kejadian_tanggal']),
                    _kv("Jam", d['waktu_kejadian_jam']),
                    const SizedBox(height: 6),
                    _kv("Jalan", d['tempat_jalan']),
                    _kv("Desa/Kel", d['tempat_desa_kel']),
                    _kv("Kecamatan", d['tempat_kecamatan']),
                    _kv("Kab/Kota", d['tempat_kab_kota']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Apa yang Terjadi", [
                    _kv("Apa yang terjadi", d['apa_terjadi']),
                    _kv("Bagaimana terjadi", d['bagaimana_terjadi']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Terlapor", [
                    _kv("Nama", d['terlapor_nama']),
                    _kv("Jenis kelamin", d['terlapor_jk']),
                    _kv("Alamat", d['terlapor_alamat']),
                    _kv("Pekerjaan", d['terlapor_pekerjaan']),
                    _kv("Kontak", d['terlapor_kontak']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Korban", [
                    _kv("Nama", d['korban_nama']),
                    _kv("Jenis kelamin", d['korban_jk']),
                    _kv("Alamat", d['korban_alamat']),
                    _kv("Pekerjaan", d['korban_pekerjaan']),
                    _kv("Kontak", d['korban_kontak']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Dilaporkan Pada", [
                    _kv("Hari", d['dilaporkan_hari']),
                    _kv("Tanggal", d['dilaporkan_tanggal']),
                    _kv("Jam", d['dilaporkan_jam']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Saksi 1", [
                    _kv("Nama", d['saksi1_nama']),
                    _kv("Umur", d['saksi1_umur']),
                    _kv("Alamat", d['saksi1_alamat']),
                    _kv("Pekerjaan", d['saksi1_pekerjaan']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Saksi 2", [
                    _kv("Nama", d['saksi2_nama']),
                    _kv("Umur", d['saksi2_umur']),
                    _kv("Alamat", d['saksi2_alamat']),
                    _kv("Pekerjaan", d['saksi2_pekerjaan']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Barang Bukti & Ringkasan", [
                    _kv("Tindak pidana", d['tindak_pidana']),
                    _kv("Barang bukti", d['barang_bukti']),
                    _kv("Uraian singkat", d['uraian_singkat']),
                    _kv("Tindakan dilakukan", d['tindakan_dilakukan']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Mengetahui", [
                    _kv("Jabatan kepala", d['mengetahui_kepala_jabatan']),
                    _kv("Nama kepala", d['mengetahui_kepala_nama']),
                    _kv("Pangkat/NRP", d['mengetahui_kepala_pangkat_nrp']),
                  ]),
                  const SizedBox(height: 12),

                  _section("Identitas Pelapor (Petugas)", [
                    _kv("Nama", d['pelapor_nama']),
                    _kv("Pangkat/NRP", d['pelapor_pangkat_nrp']),
                    _kv("Kesatuan", d['pelapor_kesatuan']),
                    _kv("Kontak", d['pelapor_kontak']),
                  ]),

                  const SizedBox(height: 14),

                  if (canRespond)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _acting ? null : _respond,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.handshake, color: Colors.white),
                        label: _acting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "RESPON / AMBIL LAPORAN",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),

                  if (!canRespond &&
                      status == 'pending' &&
                      assignedOfficer != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "⚠️ Laporan ini sudah diambil officer lain.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  if (canComplete) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _acting ? null : _complete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: _acting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "SELESAI",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }
}
