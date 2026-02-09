import 'package:flutter/material.dart';
import 'package:mobile_app/services/police_report_service.dart';
import 'detail_laporan_kepolisian_page.dart';

class DaftarLaporanKepolisianPage extends StatefulWidget {
  const DaftarLaporanKepolisianPage({super.key});

  @override
  State<DaftarLaporanKepolisianPage> createState() =>
      _DaftarLaporanKepolisianPageState();
}

class _DaftarLaporanKepolisianPageState
    extends State<DaftarLaporanKepolisianPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await PoliceReportService.fetchMine();
      setState(() => _items = data);
    } catch (e) {
      _snack("❌ $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return Colors.orange;
      case 'on_process':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text("Daftar Laporan Kepolisian"),
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
          : _items.isEmpty
          ? const Center(child: Text("Belum ada laporan."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final x = _items[i];
                final id = int.tryParse(x['id'].toString()) ?? 0;
                final status = (x['status'] ?? 'pending').toString();
                final title = (x['tindak_pidana'] ?? 'Laporan Kepolisian')
                    .toString();
                final subtitle = (x['uraian_singkat'] ?? x['apa_terjadi'] ?? '')
                    .toString();

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetailLaporanKepolisianPage(reportId: id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
