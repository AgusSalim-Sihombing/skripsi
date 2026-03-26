import 'package:flutter/material.dart';
import 'package:mobile_app/services/police_report_service.dart';
import 'detail_laporan_kepolisian_page.dart';

class BuatLaporanKepolisianPage extends StatefulWidget {
  const BuatLaporanKepolisianPage({super.key});

  @override
  State<BuatLaporanKepolisianPage> createState() =>
      _BuatLaporanKepolisianPageState();
}

class _BuatLaporanKepolisianPageState extends State<BuatLaporanKepolisianPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _reqText(String? v) =>
      (v == null || v.trim().isEmpty) ? "Wajib diisi" : null;

  String? _reqDropdown(String? v) =>
      (v == null || v.trim().isEmpty) ? "Wajib dipilih" : null;

  bool _saksiLengkap({
    required String nama,
    required String umur,
    required String alamat,
    required String pekerjaan,
  }) {
    final n = nama.trim();
    final u = umur.trim();
    final a = alamat.trim();
    final p = pekerjaan.trim();
    if (n.isEmpty && u.isEmpty && a.isEmpty && p.isEmpty)
      return false; // kosong semua
    final umurInt = int.tryParse(u);
    return n.isNotEmpty &&
        umurInt != null &&
        umurInt > 0 &&
        a.isNotEmpty &&
        p.isNotEmpty;
  }

  // tanggal/jam
  DateTime? _waktuKejadianTanggal;
  TimeOfDay? _waktuKejadianJam;
  DateTime? _dilaporkanTanggal;
  TimeOfDay? _dilaporkanJam;

  // dropdown
  String? _terlaporJk;
  String? _korbanJk;

  // controller helper
  final Map<String, TextEditingController> c = {
    "waktu_kejadian_hari": TextEditingController(),
    "tempat_jalan": TextEditingController(),
    "tempat_desa_kel": TextEditingController(),
    "tempat_kecamatan": TextEditingController(),
    "tempat_kab_kota": TextEditingController(),
    "apa_terjadi": TextEditingController(),
    "terlapor_nama": TextEditingController(),
    "terlapor_alamat": TextEditingController(),
    "terlapor_pekerjaan": TextEditingController(),
    "terlapor_kontak": TextEditingController(),
    "korban_nama": TextEditingController(),
    "korban_alamat": TextEditingController(),
    "korban_pekerjaan": TextEditingController(),
    "korban_kontak": TextEditingController(),
    "bagaimana_terjadi": TextEditingController(),
    "dilaporkan_hari": TextEditingController(),
    "tindak_pidana": TextEditingController(),
    "saksi1_nama": TextEditingController(),
    "saksi1_umur": TextEditingController(),
    "saksi1_alamat": TextEditingController(),
    "saksi1_pekerjaan": TextEditingController(),
    "saksi2_nama": TextEditingController(),
    "saksi2_umur": TextEditingController(),
    "saksi2_alamat": TextEditingController(),
    "saksi2_pekerjaan": TextEditingController(),
    "barang_bukti": TextEditingController(),
    "uraian_singkat": TextEditingController(),
    "tindakan_dilakukan": TextEditingController(),
    "mengetahui_kepala_jabatan": TextEditingController(),
    "mengetahui_kepala_nama": TextEditingController(),
    "mengetahui_kepala_pangkat_nrp": TextEditingController(),
    "pelapor_nama": TextEditingController(),
    "pelapor_pangkat_nrp": TextEditingController(),
    "pelapor_kesatuan": TextEditingController(),
    "pelapor_kontak": TextEditingController(),
  };

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _fmtTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

  Future<void> _pickDate(void Function(DateTime) onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickTime(void Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) onPicked(picked);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final s1Ok = _saksiLengkap(
      nama: c["saksi1_nama"]!.text,
      umur: c["saksi1_umur"]!.text,
      alamat: c["saksi1_alamat"]!.text,
      pekerjaan: c["saksi1_pekerjaan"]!.text,
    );

    final s2Ok = _saksiLengkap(
      nama: c["saksi2_nama"]!.text,
      umur: c["saksi2_umur"]!.text,
      alamat: c["saksi2_alamat"]!.text,
      pekerjaan: c["saksi2_pekerjaan"]!.text,
    );

    if (!s1Ok && !s2Ok) {
      _snack(
        "⚠️ Minimal isi Saksi 1 atau Saksi 2 secara lengkap (nama, umur, alamat, pekerjaan).",
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = <String, dynamic>{
        // waktu kejadian
        "waktu_kejadian_hari": c["waktu_kejadian_hari"]!.text.trim(),
        "waktu_kejadian_tanggal": _waktuKejadianTanggal == null
            ? null
            : _fmtDate(_waktuKejadianTanggal!),
        "waktu_kejadian_jam": _waktuKejadianJam == null
            ? null
            : _fmtTime(_waktuKejadianJam!),

        // tempat
        "tempat_jalan": c["tempat_jalan"]!.text.trim(),
        "tempat_desa_kel": c["tempat_desa_kel"]!.text.trim(),
        "tempat_kecamatan": c["tempat_kecamatan"]!.text.trim(),
        "tempat_kab_kota": c["tempat_kab_kota"]!.text.trim(),

        // isi laporan
        "apa_terjadi": c["apa_terjadi"]!.text.trim(),

        // terlapor
        "terlapor_nama": c["terlapor_nama"]!.text.trim(),
        "terlapor_jk": _terlaporJk,
        "terlapor_alamat": c["terlapor_alamat"]!.text.trim(),
        "terlapor_pekerjaan": c["terlapor_pekerjaan"]!.text.trim(),
        "terlapor_kontak": c["terlapor_kontak"]!.text.trim(),

        // korban
        "korban_nama": c["korban_nama"]!.text.trim(),
        "korban_jk": _korbanJk,
        "korban_alamat": c["korban_alamat"]!.text.trim(),
        "korban_pekerjaan": c["korban_pekerjaan"]!.text.trim(),
        "korban_kontak": c["korban_kontak"]!.text.trim(),

        // kronologi
        "bagaimana_terjadi": c["bagaimana_terjadi"]!.text.trim(),

        // dilaporkan
        "dilaporkan_hari": c["dilaporkan_hari"]!.text.trim(),
        "dilaporkan_tanggal": _dilaporkanTanggal == null
            ? null
            : _fmtDate(_dilaporkanTanggal!),
        "dilaporkan_jam": _dilaporkanJam == null
            ? null
            : _fmtTime(_dilaporkanJam!),

        // lainnya
        "tindak_pidana": c["tindak_pidana"]!.text.trim(),
        "saksi1_nama": c["saksi1_nama"]!.text.trim(),
        "saksi1_umur": int.tryParse(c["saksi1_umur"]!.text.trim()),
        "saksi1_alamat": c["saksi1_alamat"]!.text.trim(),
        "saksi1_pekerjaan": c["saksi1_pekerjaan"]!.text.trim(),

        "saksi2_nama": c["saksi2_nama"]!.text.trim(),
        "saksi2_umur": int.tryParse(c["saksi2_umur"]!.text.trim()),
        "saksi2_alamat": c["saksi2_alamat"]!.text.trim(),
        "saksi2_pekerjaan": c["saksi2_pekerjaan"]!.text.trim(),

        "barang_bukti": c["barang_bukti"]!.text.trim(),
        "uraian_singkat": c["uraian_singkat"]!.text.trim(),
        "tindakan_dilakukan": c["tindakan_dilakukan"]!.text.trim(),

        "mengetahui_kepala_jabatan": c["mengetahui_kepala_jabatan"]!.text
            .trim(),
        "mengetahui_kepala_nama": c["mengetahui_kepala_nama"]!.text.trim(),
        "mengetahui_kepala_pangkat_nrp": c["mengetahui_kepala_pangkat_nrp"]!
            .text
            .trim(),

        "pelapor_nama": c["pelapor_nama"]!.text.trim(),
        "pelapor_pangkat_nrp": c["pelapor_pangkat_nrp"]!.text.trim(),
        "pelapor_kesatuan": c["pelapor_kesatuan"]!.text.trim(),
        "pelapor_kontak": c["pelapor_kontak"]!.text.trim(),
      };

      // bersihin empty string -> null
      payload.removeWhere((k, v) => v is String && v.trim().isEmpty);

      final id = await PoliceReportService.createReport(payload);
      if (!mounted) return;

      _snack("✅ Laporan terkirim! (status: pending)");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetailLaporanKepolisianPage(reportId: id),
        ),
      );
    } catch (e) {
      _snack("❌ $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final ctrl in c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _tf(
    String key, {
    String? label,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c[key],
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null
            : null,
        decoration: InputDecoration(
          labelText: label ?? key,
          filled: true,
          // fillColor: const Color.fromARGB(255, 255, 255, 255),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _pickerRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            // color: Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: Text("$label: $value")),
              const Icon(Icons.edit_calendar_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jkDropdown(
    String label,
    String? value,
    void Function(String?) onChanged, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: const [
          DropdownMenuItem(value: "L", child: Text("L (Laki-laki)")),
          DropdownMenuItem(value: "P", child: Text("P (Perempuan)")),
        ],
        onChanged: onChanged,
        validator: required ? _reqDropdown : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          // fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _datePickerField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return FormField<DateTime>(
      validator: (_) => (required && value == null) ? "Wajib dipilih" : null,
      builder: (state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () async {
                  onTap();
                  state.validate();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    // color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: state.hasError
                        ? Border.all(color: Colors.red.withOpacity(0.8))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$label: ${value == null ? "-" : _fmtDate(value)}",
                        ),
                      ),
                      const Icon(Icons.edit_calendar_outlined, size: 18),
                    ],
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _timePickerField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return FormField<TimeOfDay>(
      validator: (_) => (required && value == null) ? "Wajib dipilih" : null,
      builder: (state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () async {
                  onTap();
                  state.validate();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    // color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: state.hasError
                        ? Border.all(color: Colors.red.withOpacity(0.8))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$label: ${value == null ? "-" : _fmtTime(value)}",
                        ),
                      ),
                      const Icon(Icons.access_time, size: 18),
                    ],
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 194, 194, 194),
      appBar: AppBar(
        title: const Text("Buat Laporan Kepolisian"),
        // backgroundColor: const Color(0xFF8B5A24),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _section("Waktu Kejadian", [
                _tf("waktu_kejadian_hari", label: "Hari", required: true),
                _datePickerField(
                  label: "Tanggal",
                  value: _waktuKejadianTanggal,
                  required: true,
                  onTap: () => _pickDate(
                    (d) => setState(() => _waktuKejadianTanggal = d),
                  ),
                ),
                _timePickerField(
                  label: "Jam",
                  value: _waktuKejadianJam,
                  required: true,
                  onTap: () =>
                      _pickTime((t) => setState(() => _waktuKejadianJam = t)),
                ),
              ]),

              const SizedBox(height: 12),

              _section("Tempat Kejadian", [
                _tf("tempat_jalan", label: "Jalan", required: true),
                _tf("tempat_desa_kel", label: "Desa/Kel", required: true),
                _tf("tempat_kecamatan", label: "Kecamatan", required: true),
                _tf("tempat_kab_kota", label: "Kab/Kota", required: true),
              ]),

              const SizedBox(height: 12),

              _section("Peristiwa", [
                _tf(
                  "apa_terjadi",
                  label: "Apa yang terjadi",
                  required: true,
                  maxLines: 4,
                ),
                _tf(
                  "bagaimana_terjadi",
                  label: "Bagaimana terjadi",
                  required: true,
                  maxLines: 4,
                ),
                _tf(
                  "tindak_pidana",
                  label: "Tindak pidana apa",
                  required: true,
                ),
              ]),

              const SizedBox(height: 12),

              _section("Terlapor", [
                _tf("terlapor_nama", label: "Nama", required: true),
                _jkDropdown(
                  "Jenis Kelamin",
                  _terlaporJk,
                  (v) => setState(() => _terlaporJk = v),
                  required: true,
                ),
                _tf(
                  "terlapor_alamat",
                  label: "Alamat",
                  required: true,
                  maxLines: 2,
                ),
                _tf("terlapor_pekerjaan", label: "Pekerjaan", required: true),
                _tf(
                  "terlapor_kontak",
                  label: "No.Telp/Faks/Email",
                  required: true,
                ),
              ]),

              const SizedBox(height: 12),

              _section("Korban", [
                _tf("korban_nama", label: "Nama", required: true),
                _jkDropdown(
                  "Jenis Kelamin",
                  _korbanJk,
                  (v) => setState(() => _korbanJk = v),
                  required: true,
                ),
                _tf(
                  "korban_alamat",
                  label: "Alamat",
                  required: true,
                  maxLines: 2,
                ),
                _tf("korban_pekerjaan", label: "Pekerjaan", required: true),
                _tf(
                  "korban_kontak",
                  label: "No.Telp/Faks/Email",
                  required: true,
                ),
              ]),

              const SizedBox(height: 12),

              _section("Saksi & Bukti", [
                _tf("saksi1_nama", label: "Saksi 1 - Nama"),
                _tf(
                  "saksi1_umur",
                  label: "Saksi 1 - Umur",
                  keyboardType: TextInputType.number,
                ),
                _tf("saksi1_alamat", label: "Saksi 1 - Alamat", maxLines: 2),
                _tf("saksi1_pekerjaan", label: "Saksi 1 - Pekerjaan"),
                const Divider(),

                _tf("saksi2_nama", label: "Saksi 2 - Nama"),
                _tf(
                  "saksi2_umur",
                  label: "Saksi 2 - Umur",
                  keyboardType: TextInputType.number,
                ),
                _tf("saksi2_alamat", label: "Saksi 2 - Alamat", maxLines: 2),
                _tf("saksi2_pekerjaan", label: "Saksi 2 - Pekerjaan"),
                const Divider(),

                _tf(
                  "barang_bukti",
                  label: "Barang bukti",
                  required: true,
                  maxLines: 3,
                ),
                _tf(
                  "uraian_singkat",
                  label: "Uraian singkat yang dilaporkan",
                  required: true,
                  maxLines: 4,
                ),
              ]),

              const SizedBox(height: 12),

              _section("Dilaporkan Pada", [
                _tf("dilaporkan_hari", label: "Hari"),
                _pickerRow(
                  label: "Tanggal",
                  value: _dilaporkanTanggal == null
                      ? "-"
                      : _fmtDate(_dilaporkanTanggal!),
                  onTap: () =>
                      _pickDate((d) => setState(() => _dilaporkanTanggal = d)),
                ),
                _pickerRow(
                  label: "Jam",
                  value: _dilaporkanJam == null
                      ? "-"
                      : _fmtTime(_dilaporkanJam!),
                  onTap: () =>
                      _pickTime((t) => setState(() => _dilaporkanJam = t)),
                ),
              ]),
              const SizedBox(height: 12),

              _section("Penutup (opsional)", [
                _tf(
                  "tindakan_dilakukan",
                  label: "Tindakan yang telah dilakukan",
                  maxLines: 3,
                ),
                _tf("mengetahui_kepala_jabatan", label: "Mengetahui - Jabatan"),
                _tf("mengetahui_kepala_nama", label: "Mengetahui - Nama"),
                _tf(
                  "mengetahui_kepala_pangkat_nrp",
                  label: "Mengetahui - Pangkat/NRP",
                ),
                const Divider(),
                _tf("pelapor_nama", label: "Pelapor - Nama"),
                _tf("pelapor_pangkat_nrp", label: "Pelapor - Pangkat/NRP"),
                _tf("pelapor_kesatuan", label: "Pelapor - Kesatuan"),
                _tf("pelapor_kontak", label: "Pelapor - Kontak"),
              ]),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5A24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "KIRIM LAPORAN",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
