import 'package:flutter/material.dart';
import 'package:mobile_app/services/police_report_service.dart';
import 'field_report_detail_page.dart';

class OfficerFieldReportInboxPage extends StatefulWidget {
  const OfficerFieldReportInboxPage({super.key});

  @override
  State<OfficerFieldReportInboxPage> createState() =>
      _OfficerFieldReportInboxPageState();
}

class _OfficerFieldReportInboxPageState
    extends State<OfficerFieldReportInboxPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _loading1 = true, _loading2 = true;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _mine = [];

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadPending();
    _loadMine();
  }

  Future<void> _loadPending() async {
    setState(() => _loading1 = true);
    try {
      final data = await PoliceReportService.fetchPending();
      setState(() => _pending = data);
    } catch (e) {
      _snack("❌ $e");
    } finally {
      if (mounted) setState(() => _loading1 = false);
    }
  }

  Future<void> _loadMine() async {
    setState(() => _loading2 = true);
    try {
      final data = await PoliceReportService.fetchMineOfficer();
      setState(() => _mine = data);
    } catch (e) {
      _snack("❌ $e");
    } finally {
      if (mounted) setState(() => _loading2 = false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Widget _list(List<Map<String, dynamic>> items, bool loading) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return const Center(child: Text("Kosong."));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final x = items[i];
        final id = int.tryParse(x['id'].toString()) ?? 0;
        final title = (x['tindak_pidana'] ?? 'Field Report').toString();
        final sub = (x['uraian_singkat'] ?? x['apa_terjadi'] ?? '').toString();

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OfficerFieldReportDetailPage(reportId: id),
                ),
              );
              // balik dari detail -> refresh biar state sinkron
              _loadPending();
              _loadMine();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text("Field Report"),
        backgroundColor: const Color(0xFF8B5A24),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Saya Tangani"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _loadPending();
              _loadMine();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [_list(_pending, _loading1), _list(_mine, _loading2)],
      ),
    );
  }
}
