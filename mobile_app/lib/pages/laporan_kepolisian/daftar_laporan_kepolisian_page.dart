// import 'package:flutter/material.dart';
// import 'package:mobile_app/services/police_report_service.dart';
// import 'detail_laporan_kepolisian_page.dart';

// class DaftarLaporanKepolisianPage extends StatefulWidget {
//   const DaftarLaporanKepolisianPage({super.key});

//   @override
//   State<DaftarLaporanKepolisianPage> createState() =>
//       _DaftarLaporanKepolisianPageState();
// }

// class _DaftarLaporanKepolisianPageState
//     extends State<DaftarLaporanKepolisianPage> {
//   bool _loading = true;
//   List<Map<String, dynamic>> _items = [];

//   void _snack(String m) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final data = await PoliceReportService.fetchMine();
//       setState(() => _items = data);
//     } catch (e) {
//       _snack("❌ $e");
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Color _statusColor(String s) {
//     switch (s) {
//       case 'pending':
//         return Colors.orange;
//       case 'on_process':
//         return Colors.blue;
//       case 'selesai':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: const Color(0xFFF4F4F4),
//       appBar: AppBar(
//         title: const Text("Daftar Laporan Kepolisian"),
//         centerTitle: true,
//         // backgroundColor: const Color(0xFF8B5A24),
//         actions: [
//           IconButton(
//             onPressed: _loading ? null : _load,
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _items.isEmpty
//           ? const Center(child: Text("Belum ada laporan."))
//           : ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: _items.length,
//               itemBuilder: (_, i) {
//                 final x = _items[i];
//                 final id = int.tryParse(x['id'].toString()) ?? 0;
//                 final status = (x['status'] ?? 'pending').toString();
//                 final title = (x['tindak_pidana'] ?? 'Laporan Kepolisian')
//                     .toString();
//                 final subtitle = (x['apa_terjadi'] ?? x['uraian_singkat'] ?? '')
//                     .toString();

//                 return Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: ListTile(
//                     title: Text(
//                       title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     subtitle: Text(
//                       subtitle,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _statusColor(status).withOpacity(0.12),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: Text(
//                         status,
//                         style: TextStyle(
//                           color: _statusColor(status),
//                           fontWeight: FontWeight.w800,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) =>
//                               DetailLaporanKepolisianPage(reportId: id),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:mobile_app/services/police_report_service.dart';
import 'package:mobile_app/theme/app_theme.dart';
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

  // Helper untuk format teks dan warna status
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

  // Helper untuk memformat tanggal dari ISO 8601 string
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        // animateColor: true,
        title: const Text(
          "Riwayat Laporan Kepolisian",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // elevation: 0,

        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final id = int.tryParse(item['id'].toString()) ?? 0;
                        final statusStr = (item['status'] ?? 'pending')
                            .toString();
                        final tindakPidana =
                            (item['tindak_pidana'] ??
                                    'Tindak Pidana Tidak Diketahui')
                                .toString();
                        final lokasi =
                            (item['tempat_kab_kota'] ??
                                    'Lokasi tidak disebutkan')
                                .toString();
                        final tanggal = _formatDate(
                          item['created_at']?.toString(),
                        );

                        final statusProps = _statusProps(statusStr);

                        return Card(
                          
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),

                          ),
                          color: AppColors.borderSoft,

                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailLaporanKepolisianPage(reportId: id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- Bagian Atas: ID & Badge Status ---
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "ID Laporan: #$id",
                                        style: const TextStyle(
                                          fontSize: 12,
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
                                          color: statusProps['color']
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                  const Divider(
                                    height: 24,
                                    color: Colors.black12,
                                  ),

                                  // --- Bagian Tengah: Judul Laporan (Tindak Pidana) ---
                                  Text(
                                    tindakPidana,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),

                                  // --- Bagian Bawah: Info Lokasi & Waktu ---
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
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
                                      const SizedBox(width: 6),
                                      Text(
                                        tanggal,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
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

  // Tampilan jika data kosong
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.description_outlined, size: 80, color: Colors.black26),
        const SizedBox(height: 16),
        const Text(
          "Belum Ada Laporan",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Laporan yang Anda buat akan muncul di sini.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black45),
        ),
      ],
    );
  }
}
