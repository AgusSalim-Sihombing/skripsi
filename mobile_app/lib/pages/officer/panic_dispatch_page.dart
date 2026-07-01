import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/officer/panic_detail_page.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:mobile_app/theme/app_theme.dart';

class PanicDispatchPage extends StatefulWidget {
  final String token;
  final String baseUrl; // http://IP:3001

  const PanicDispatchPage({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<PanicDispatchPage> createState() => _PanicDispatchPageState();
}

class _PanicDispatchPageState extends State<PanicDispatchPage> {
  final SocketService _socket = SocketService();

  bool _loading = true;
  String? _error;
  final List<Map<String, dynamic>> _items = [];

  final TextEditingController _searchC = TextEditingController();
  String _q = "";

  bool _isAssigned(Map<String, dynamic> item) {
    final status = (item["status"] ?? "").toString().toUpperCase();
    return status == "ASSIGNED";
  }

  String _statusLabel(dynamic status) {
    final s = (status ?? "").toString().toUpperCase();

    if (s == "ASSIGNED") return "Diproses";
    if (s == "OPEN") return "Menunggu";
    if (s == "RESOLVED") return "Selesai";
    if (s == "CANCELLED") return "Dibatalkan";

    return s.isEmpty ? "-" : s;
  }

  @override
  void initState() {
    super.initState();

    // connect socket (kalau udah connect dari home, dia skip)
    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    // load awal dari API (biar gak tergantung banner yg udah lewat)
    _fetchOfferedPanics();

    // realtime masuk -> masuk list juga
    _socket.on("panic:new", _onPanicNew);

    // kalau sudah diambil officer lain -> remove dari list
    _socket.on("panic:assigned", _onPanicAssigned);

    _searchC.addListener(() {
      setState(() => _q = _searchC.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchC.dispose();

    // penting: karena SocketService kamu singleton,
    // jangan disconnect di sini (nanti HomePage ikut putus).
    // Cukup off listener aja.
    _socket.off("panic:new");
    _socket.off("panic:assigned");

    super.dispose();
  }

  // void _onPanicNew(dynamic payload) {
  //   final data = Map<String, dynamic>.from(payload);
  //   final pid = data["panicId"];

  //   setState(() {
  //     final exists = _items.any((e) => e["panicId"] == pid);
  //     if (!exists) {
  //       _items.insert(0, data); // masuk paling atas
  //     }
  //   });
  // }

  void _onPanicNew(dynamic payload) {
    final data = Map<String, dynamic>.from(payload);

    // Karena halaman ini hanya menampilkan panic ASSIGNED,
    // panic baru yang masih OPEN tidak perlu dimasukkan.
    if (!_isAssigned(data)) return;

    final pid = data["panicId"] ?? data["id"];

    setState(() {
      final exists = _items.any((e) => (e["panicId"] ?? e["id"]) == pid);
      if (!exists) {
        _items.insert(0, data);
      }
    });
  }

  // void _onPanicAssigned(dynamic payload) {
  //   final data = Map<String, dynamic>.from(payload);
  //   final pid = data["panicId"];

  //   setState(() {
  //     _items.removeWhere((e) => e["panicId"] == pid);
  //   });
  // }

  void _onPanicAssigned(dynamic payload) {
    final data = Map<String, dynamic>.from(payload);
    final pid = data["panicId"] ?? data["id"];

    if (!_isAssigned(data)) {
      setState(() {
        _items.removeWhere((e) => (e["panicId"] ?? e["id"]) == pid);
      });
      return;
    }

    setState(() {
      final index = _items.indexWhere((e) => (e["panicId"] ?? e["id"]) == pid);

      if (index >= 0) {
        _items[index] = {..._items[index], ...data, "status": "ASSIGNED"};
      } else {
        _items.insert(0, {...data, "status": "ASSIGNED"});
      }
    });
  }

  Future<void> _fetchOfferedPanics() async {
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
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (resp.statusCode != 200) {
        setState(() {
          _error = "Gagal load panic diproses (${resp.statusCode})";
          _loading = false;
        });
        return;
      }

      final list = jsonDecode(resp.body) as List<dynamic>;

      final mapped = list.map((e) => Map<String, dynamic>.from(e)).where((x) {
        final status = (x["status"] ?? "").toString().toUpperCase();
        return status == "ASSIGNED";
      }).toList();

      mapped.sort((a, b) {
        final ad =
            (a["respondedAt"] ??
                    a["responded_at"] ??
                    a["created_at"] ??
                    a["createdAt"] ??
                    "")
                .toString();
        final bd =
            (b["respondedAt"] ??
                    b["responded_at"] ??
                    b["created_at"] ??
                    b["createdAt"] ??
                    "")
                .toString();
        return bd.compareTo(ad);
      });

      setState(() {
        _items
          ..clear()
          ..addAll(mapped);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final assignedItems = _items.where((x) {
      final status = (x["status"] ?? "").toString().toUpperCase();
      return status == "ASSIGNED";
    }).toList();

    if (_q.isEmpty) return assignedItems;

    return assignedItems.where((x) {
      final fromName = (x["fromName"] ?? x["citizen_name"] ?? "")
          .toString()
          .toLowerCase();
      final addr = (x["address"] ?? "").toString().toLowerCase();
      final pid = (x["panicId"] ?? x["id"] ?? "").toString().toLowerCase();

      return fromName.contains(_q) || addr.contains(_q) || pid.contains(_q);
    }).toList();
  }

  String _fmtDistance(dynamic distanceM) {
    final n = (distanceM is num)
        ? distanceM.toDouble()
        : double.tryParse("$distanceM");
    if (n == null) return "-";
    if (n < 1000) return "${n.toStringAsFixed(0)} m";
    return "${(n / 1000).toStringAsFixed(2)} km";
  }

  String _fmtCoord(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse("$v");
    if (n == null) return "-";
    return n.toStringAsFixed(6);
  }

  String _fmtTime(dynamic iso) {
    if (iso == null || iso.toString().isEmpty) return "-";

    try {
      final dt = DateTime.parse(iso.toString()).toLocal();

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
      return iso.toString();
    }
  }

  Map<String, dynamic> _statusProps(String status) {
    switch (status.toUpperCase()) {
      case "RESOLVED":
        return {'text': 'Selesai', 'color': Colors.green};
      case "ASSIGNED":
        return {'text': 'Diproses', 'color': Colors.orange};
      default:
        return {'text': status.toUpperCase(), 'color': Colors.red};
    }
  }

  Future<void> _openDetail(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PanicDetailPage(
          token: widget.token,
          baseUrl: widget.baseUrl,
          panicData: item,
        ),
      ),
    );

    // habis balik, refresh (biar kalau dia udah respon/assigned, list update)
    await _fetchOfferedPanics();
  }

  @override
  Widget build(BuildContext context) {
    // const primary = Color(0xFF8B5A24);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panic Dispatch"),
        // backgroundColor: primary,
        actions: [
          IconButton(
            onPressed: _fetchOfferedPanics,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: "Cari nama / alamat / panicId…",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchOfferedPanics,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null)
                  ? ListView(
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    )
                  : (_filtered.isEmpty)
                  ? ListView(
                      children: const [
                        SizedBox(height: 70),
                        Center(
                          child: Text(
                            "Belum ada panic yang sedang diproses.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final x = _filtered[i];

                        final pid = x["panicId"] ?? x["id"];

                        final fromName =
                            (x["fromName"] ??
                                    x["citizen_name"] ??
                                    "Tidak Diketahui")
                                .toString();

                        final addr =
                            (x["address"] ??
                                    "${_fmtCoord(x["lat"])}, ${_fmtCoord(x["lng"])}")
                                .toString();

                        final statusStr = (x["status"] ?? "-").toString();
                        final dist = _fmtDistance(x["distanceM"]);

                        final respondedAt = _fmtTime(
                          x["respondedAt"] ??
                              x["responded_at"] ??
                              x["assignedAt"] ??
                              x["assigned_at"] ??
                              x["updatedAt"] ??
                              x["updated_at"],
                        );

                        final statusProps = _statusProps(statusStr);

                        return Card(
                          color: AppColors.textMuted4,
                          shadowColor: Colors.black12,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openDetail(x),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: ID & Badge Status
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

                                  // Nama Pelapor
                                  Text(
                                    fromName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Lokasi
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

                                  // Footer Pills
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
