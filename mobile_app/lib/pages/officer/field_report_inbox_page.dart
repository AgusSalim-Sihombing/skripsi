// import 'package:flutter/material.dart';
// import 'package:mobile_app/services/police_report_service.dart';
// import 'field_report_detail_page.dart';

// class OfficerFieldReportInboxPage extends StatefulWidget {
//   const OfficerFieldReportInboxPage({super.key});

//   @override
//   State<OfficerFieldReportInboxPage> createState() =>
//       _OfficerFieldReportInboxPageState();
// }

// class _OfficerFieldReportInboxPageState
//     extends State<OfficerFieldReportInboxPage>
//     with SingleTickerProviderStateMixin {
//   late final TabController _tab;
//   bool _loading1 = true, _loading2 = true;
//   List<Map<String, dynamic>> _pending = [];
//   List<Map<String, dynamic>> _mine = [];

//   void _snack(String m) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

//   @override
//   void initState() {
//     super.initState();
//     _tab = TabController(length: 2, vsync: this);
//     _loadPending();
//     _loadMine();
//   }

//   Future<void> _loadPending() async {
//     setState(() => _loading1 = true);
//     try {
//       final data = await PoliceReportService.fetchPending();
//       setState(() => _pending = data);
//     } catch (e) {
//       _snack("❌ $e");
//     } finally {
//       if (mounted) setState(() => _loading1 = false);
//     }
//   }

//   Future<void> _loadMine() async {
//     setState(() => _loading2 = true);
//     try {
//       final data = await PoliceReportService.fetchMineOfficer();
//       setState(() => _mine = data);
//     } catch (e) {
//       _snack("❌ $e");
//     } finally {
//       if (mounted) setState(() => _loading2 = false);
//     }
//   }

//   @override
//   void dispose() {
//     _tab.dispose();
//     super.dispose();
//   }

//   Widget _list(List<Map<String, dynamic>> items, bool loading) {
//     if (loading) return const Center(child: CircularProgressIndicator());
//     if (items.isEmpty) return const Center(child: Text("Kosong."));
//     return ListView.builder(
//       padding: const EdgeInsets.all(12),
//       itemCount: items.length,
//       itemBuilder: (_, i) {
//         final x = items[i];
//         final id = int.tryParse(x['id'].toString()) ?? 0;
//         final title = (x['tindak_pidana'] ?? 'Field Report').toString();
//         final sub = (x['uraian_singkat'] ?? x['apa_terjadi'] ?? '').toString();

//         return Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: ListTile(
//             title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
//             subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
//             trailing: const Icon(Icons.chevron_right),
//             onTap: () async {
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => OfficerFieldReportDetailPage(reportId: id, reportTitle: title),
//                 ),
//               );
//               // balik dari detail -> refresh biar state sinkron
//               _loadPending();
//               _loadMine();
//             },
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: const Color(0xFFF4F4F4),
//       appBar: AppBar(
//         title: const Text("Field Report"),
//         centerTitle: true,
//         // backgroundColor: const Color(0xFF8B5A24),
//         bottom: TabBar(
//           controller: _tab,
//           tabs: const [
//             Tab(text: "Pending"),
//             Tab(text: "Saya Tangani"),
//           ],
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {
//               _loadPending();
//               _loadMine();
//             },
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//       body: TabBarView(
//         controller: _tab,
//         children: [_list(_pending, _loading1), _list(_mine, _loading2)],
//       ),
//     );
//   }
// }

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
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadPending(), _loadMine()]);
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

  // Helper untuk memformat tanggal
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$day $month $year, $hour:$minute WIB";
    } catch (e) {
      return dateStr;
    }
  }

  // UI untuk State Kosong
  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.inbox_outlined, size: 80, color: Colors.black26),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // Builder utama untuk List
  Widget _list(
    List<Map<String, dynamic>> items,
    bool loading,
    Future<void> Function() onRefresh,
  ) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? _buildEmptyState("Tidak ada laporan saat ini.")
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final x = items[i];
                final id = int.tryParse(x['id'].toString()) ?? 0;
                final statusStr = (x['status'] ?? 'pending').toString();
                final title =
                    (x['tindak_pidana'] ?? 'Tindak Pidana Tidak Diketahui')
                        .toString();
                final lokasi =
                    (x['tempat_kab_kota'] ?? 'Lokasi tidak disebutkan')
                        .toString();
                final tanggal = _formatDate(x['created_at']?.toString());

                // pelapor_nama didapat dari join table di listPending model sebelumnya
                final pelapor = x['pelapor_nama']?.toString();

                final statusProps = _statusProps(statusStr);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfficerFieldReportDetailPage(
                            reportId: id,
                            reportTitle: title,
                          ),
                        ),
                      );
                      // Refresh otomatis setelah kembali dari halaman detail
                      _loadAll();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Header: ID & Badge Status ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Laporan: #$id",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusProps['color'].withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusProps['text'],
                                  style: TextStyle(
                                    color: statusProps['color'],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.black12),

                          // --- Body: Tindak Pidana ---
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(
                                0xFF1E3A8A,
                              ), // Navy agar terlihat tegas
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),

                          // --- Footer: Lokasi, Waktu, Pelapor ---
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lokasi,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tanggal,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          if (pelapor != null && pelapor.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Pelapor: $pelapor",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Field Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Menunggu"),
            Tab(text: "Saya Tangani"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loading1 || _loading2 ? null : _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _list(_pending, _loading1, _loadPending),
          _list(_mine, _loading2, _loadMine),
        ],
      ),
    );
  }
}
