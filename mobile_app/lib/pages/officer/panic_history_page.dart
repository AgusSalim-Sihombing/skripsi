// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'panic_history_detail_page.dart';

// class PanicHistoryPage extends StatefulWidget {
//   final String token;
//   final String baseUrl;

//   const PanicHistoryPage({
//     super.key,
//     required this.token,
//     required this.baseUrl,
//   });

//   @override
//   State<PanicHistoryPage> createState() => _PanicHistoryPageState();
// }

// class _PanicHistoryPageState extends State<PanicHistoryPage> {
//   bool _loading = true;
//   String? _error;
//   final List<Map<String, dynamic>> _items = [];
//   String _q = "";

//   @override
//   void initState() {
//     super.initState();
//     _fetch();
//   }

//   Future<void> _fetch() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       final resp = await http.get(
//         Uri.parse("${widget.baseUrl}/api/mobile/officer/panic/history"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer ${widget.token}",
//         },
//       );

//       if (resp.statusCode != 200) {
//         setState(() {
//           _error = "Gagal load riwayat (${resp.statusCode})";
//           _loading = false;
//         });
//         return;
//       }

//       final list = (jsonDecode(resp.body) as List<dynamic>)
//           .map((e) => Map<String, dynamic>.from(e))
//           .toList();

//       setState(() {
//         _items
//           ..clear()
//           ..addAll(list);
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = "Error: $e";
//         _loading = false;
//       });
//     }
//   }

//   String _fmtDistance(dynamic distanceM) {
//     final n = (distanceM is num)
//         ? distanceM.toDouble()
//         : double.tryParse("$distanceM");
//     if (n == null) return "-";
//     if (n < 1000) return "${n.toStringAsFixed(0)} m";
//     return "${(n / 1000).toStringAsFixed(2)} km";
//   }

//   String _fmtTime(String? iso) {
//     if (iso == null || iso.isEmpty) return "-";
//     try {
//       final dt = DateTime.parse(iso).toLocal();
//       String two(int v) => v.toString().padLeft(2, "0");
//       return "${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
//     } catch (_) {
//       return iso;
//     }
//   }

//   List<Map<String, dynamic>> get _filtered {
//     if (_q.trim().isEmpty) return _items;
//     final q = _q.toLowerCase();
//     return _items.where((x) {
//       final from = (x["fromName"] ?? "").toString().toLowerCase();
//       final addr = (x["address"] ?? "").toString().toLowerCase();
//       final pid = (x["panicId"] ?? "").toString().toLowerCase();
//       final status = (x["status"] ?? "").toString().toLowerCase();
//       return from.contains(q) ||
//           addr.contains(q) ||
//           pid.contains(q) ||
//           status.contains(q);
//     }).toList();
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case "RESOLVED":
//         return Colors.green;
//       case "ASSIGNED":
//         return Colors.orange;
//       default:
//         return Colors.red;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const primary = Color(0xFF8B5A24);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Riwayat Panic"),
//         backgroundColor: primary,
//         actions: [
//           IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
//             child: TextField(
//               onChanged: (v) => setState(() => _q = v),
//               decoration: InputDecoration(
//                 hintText: "Cari nama / alamat / panicId / status…",
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 12,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(16),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(16),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: RefreshIndicator(
//               onRefresh: _fetch,
//               child: _loading
//                   ? const Center(child: CircularProgressIndicator())
//                   : (_error != null)
//                   ? ListView(
//                       children: [
//                         const SizedBox(height: 70),
//                         Center(
//                           child: Text(
//                             _error!,
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       ],
//                     )
//                   : (_filtered.isEmpty)
//                   ? ListView(
//                       children: const [
//                         SizedBox(height: 70),
//                         Center(
//                           child: Text(
//                             "Belum ada riwayat panic yang kamu respon.",
//                           ),
//                         ),
//                       ],
//                     )
//                   : ListView.separated(
//                       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                       itemCount: _filtered.length,
//                       separatorBuilder: (_, __) => const SizedBox(height: 10),
//                       itemBuilder: (context, i) {
//                         final x = _filtered[i];

//                         final pid = x["panicId"];
//                         final fromName = (x["fromName"] ?? "-").toString();
//                         final addr = (x["address"] ?? "-").toString();
//                         final status = (x["status"] ?? "-").toString();
//                         final dist = _fmtDistance(x["distanceM"]);
//                         final respondedAt = _fmtTime(
//                           x["respondedAt"]?.toString(),
//                         );

//                         return InkWell(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => PanicHistoryDetailPage(
//                                   token: widget.token,
//                                   baseUrl: widget.baseUrl,
//                                   panicId: (pid as num).toInt(),
//                                 ),
//                               ),
//                             );
//                           },
//                           borderRadius: BorderRadius.circular(16),
//                           child: Container(
//                             padding: const EdgeInsets.all(14),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(16),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.05),
//                                   blurRadius: 10,
//                                   offset: const Offset(0, 6),
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Text(
//                                       "Panic ID: $pid",
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w800,
//                                       ),
//                                     ),
//                                     const Spacer(),
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 10,
//                                         vertical: 6,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: _statusColor(
//                                           status,
//                                         ).withOpacity(0.12),
//                                         borderRadius: BorderRadius.circular(
//                                           999,
//                                         ),
//                                         border: Border.all(
//                                           color: _statusColor(
//                                             status,
//                                           ).withOpacity(0.35),
//                                         ),
//                                       ),
//                                       child: Text(
//                                         status,
//                                         style: TextStyle(
//                                           color: _statusColor(status),
//                                           fontWeight: FontWeight.w800,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   "Dari: $fromName",
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   "Lokasi: $addr",
//                                   style: const TextStyle(color: Colors.black87),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Row(
//                                   children: [
//                                     _pill("Jarak saat dispatch", dist),
//                                     const SizedBox(width: 10),
//                                     _pill("Waktu respon", respondedAt),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _pill(String label, String value) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontSize: 11, color: Colors.black54),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               value,
//               style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/theme/app_theme.dart';
import 'panic_history_detail_page.dart';

class PanicHistoryPage extends StatefulWidget {
  final String token;
  final String baseUrl;

  const PanicHistoryPage({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<PanicHistoryPage> createState() => _PanicHistoryPageState();
}

class _PanicHistoryPageState extends State<PanicHistoryPage> {
  bool _loading = true;
  String? _error;
  final List<Map<String, dynamic>> _items = [];
  String _q = "";

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await http.get(
        Uri.parse("${widget.baseUrl}/api/mobile/officer/panic/history"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (resp.statusCode != 200) {
        setState(() {
          _error = "Gagal load riwayat (${resp.statusCode})";
          _loading = false;
        });
        return;
      }

      final list = (jsonDecode(resp.body) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  String _fmtDistance(dynamic distanceM) {
    final n = (distanceM is num)
        ? distanceM.toDouble()
        : double.tryParse("$distanceM");
    if (n == null) return "-";
    if (n < 1000) return "${n.toStringAsFixed(0)} m";
    return "${(n / 1000).toStringAsFixed(2)} km";
  }

  String _fmtTime(String? iso) {
    if (iso == null || iso.isEmpty) return "-";
    try {
      final dt = DateTime.parse(iso).toLocal();
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
      final hour = dt.hour.toString().padLeft(2, "0");
      final minute = dt.minute.toString().padLeft(2, "0");
      return "$day $month $year, $hour:$minute";
    } catch (_) {
      return iso;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_q.trim().isEmpty) return _items;
    final q = _q.toLowerCase();
    return _items.where((x) {
      final from = (x["fromName"] ?? "").toString().toLowerCase();
      final addr = (x["address"] ?? "").toString().toLowerCase();
      final pid = (x["panicId"] ?? "").toString().toLowerCase();
      final status = (x["status"] ?? "").toString().toLowerCase();
      return from.contains(q) ||
          addr.contains(q) ||
          pid.contains(q) ||
          status.contains(q);
    }).toList();
  }

  Map<String, dynamic> _statusProps(String status) {
    switch (status) {
      case "RESOLVED":
        return {'text': 'Selesai', 'color': Colors.green};
      case "ASSIGNED":
        return {'text': 'Diproses', 'color': Colors.orange};
      default:
        return {'text': status.toUpperCase(), 'color': Colors.red};
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF8B5A24);

    return Scaffold(
      // backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Riwayat Panic",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // backgroundColor: primary,
        // elevation: 0,
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            // color: primary,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: "Cari nama, alamat, atau ID...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- LIST CONTENT ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null)
                  ? _buildEmptyState(Icons.error_outline, _error!, Colors.red)
                  : (_filtered.isEmpty)
                  ? _buildEmptyState(
                      Icons.history_toggle_off,
                      _q.isEmpty
                          ? "Belum ada riwayat panic yang kamu respon."
                          : "Pencarian tidak ditemukan.",
                      Colors.black45,
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final x = _filtered[i];

                        final pid = x["panicId"];
                        final fromName = (x["fromName"] ?? "Tidak Diketahui")
                            .toString();
                        final addr = (x["address"] ?? "Lokasi tidak tersedia")
                            .toString();
                        final statusStr = (x["status"] ?? "-").toString();
                        final dist = _fmtDistance(x["distanceM"]);
                        final respondedAt = _fmtTime(
                          x["respondedAt"]?.toString(),
                        );

                        final statusProps = _statusProps(statusStr);

                        return Card(
                          color: AppColors.textMuted4,
                          // elevation: 2,
                          shadowColor: Colors.black12,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PanicHistoryDetailPage(
                                    token: widget.token,
                                    baseUrl: widget.baseUrl,
                                    panicId: (pid as num).toInt(),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // -- Header: ID & Badge --
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Panic ID: #$pid",
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
                                              .withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          statusProps['text'],
                                          style: TextStyle(
                                            color: statusProps['color'],
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // -- Body: Nama & Lokasi --
                                  Text(
                                    fromName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          addr,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // -- Footer: Pills --
                                  Row(
                                    children: [
                                      _pill(
                                        Icons.route_outlined,
                                        "Jarak",
                                        dist,
                                      ),
                                      const SizedBox(width: 10),
                                      _pill(
                                        Icons.access_time_rounded,
                                        "Direspon Pada",
                                        respondedAt,
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
          ),
        ],
      ),
    );
  }

  // Komponen untuk Layout Empty State
  Widget _buildEmptyState(IconData icon, String message, Color color) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(icon, size: 80, color: color.withOpacity(0.5)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // Komponen kotak informasi (Pill) dengan Ikon
  Widget _pill(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.textWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black38),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
