import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/officer/panic_detail_page.dart';
import 'package:mobile_app/services/socket_service.dart';

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

  void _onPanicNew(dynamic payload) {
    final data = Map<String, dynamic>.from(payload);
    final pid = data["panicId"];

    setState(() {
      final exists = _items.any((e) => e["panicId"] == pid);
      if (!exists) {
        _items.insert(0, data); // masuk paling atas
      }
    });
  }

  void _onPanicAssigned(dynamic payload) {
    final data = Map<String, dynamic>.from(payload);
    final pid = data["panicId"];

    setState(() {
      _items.removeWhere((e) => e["panicId"] == pid);
    });
  }

  Future<void> _fetchOfferedPanics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await http.get(
        Uri.parse("${widget.baseUrl}/api/mobile/officer/panic/offered"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (resp.statusCode != 200) {
        setState(() {
          _error = "Gagal load dispatch (${resp.statusCode})";
          _loading = false;
        });
        return;
      }

      final list = jsonDecode(resp.body) as List<dynamic>;
      final mapped = list.map((e) => Map<String, dynamic>.from(e)).toList();

      // sort by created_at/createdAt desc (kalau ada)
      mapped.sort((a, b) {
        final ad = (a["created_at"] ?? a["createdAt"] ?? "").toString();
        final bd = (b["created_at"] ?? b["createdAt"] ?? "").toString();
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
    if (_q.isEmpty) return _items;

    return _items.where((x) {
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
    const primary = Color(0xFF8B5A24);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panic Dispatch"),
        backgroundColor: primary,
        actions: [
          IconButton(
            onPressed: _fetchOfferedPanics,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
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
                            "Belum ada panic masuk.\n(atau semuanya udah diambil officer lain)",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final x = _filtered[i];

                        final pid = x["panicId"] ?? x["id"];
                        final fromName = (x["fromName"] ?? "-").toString();
                        final addr =
                            (x["address"] ??
                                    "${_fmtCoord(x["lat"])}, ${_fmtCoord(x["lng"])}")
                                .toString();
                        final dist = _fmtDistance(x["distanceM"]);
                        final status = (x["status"] ?? "OPEN").toString();

                        return InkWell(
                          onTap: () => _openDetail(x),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: status == "ASSIGNED"
                                    ? Colors.green.withOpacity(0.35)
                                    : Colors.red.withOpacity(0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC62828),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "PANIC",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "ID: $pid",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                Text(
                                  "Dari: $fromName",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Lokasi: $addr",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    _pill(
                                      "Jarak",
                                      dist,
                                      Icons.social_distance_rounded,
                                    ),
                                    const SizedBox(width: 10),
                                    _pill(
                                      "Status",
                                      status,
                                      Icons.info_outline_rounded,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openDetail(x),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      "BUKA DETAIL / RESPON",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _pill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
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
