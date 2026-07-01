import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/officer/panic_detail_page.dart';
import 'package:mobile_app/pages/officer/panic_history_detail_page.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:mobile_app/theme/app_theme.dart';

class PanicOpenDispatchPage extends StatefulWidget {
  final String token;
  final String baseUrl;

  const PanicOpenDispatchPage({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<PanicOpenDispatchPage> createState() => _PanicOpenDispatchPageState();
}

class _PanicOpenDispatchPageState extends State<PanicOpenDispatchPage> {
  final SocketService _socket = SocketService();
  final TextEditingController _searchC = TextEditingController();

  bool _loadingOpen = true;
  bool _loadingAssigned = true;

  String? _errorOpen;
  String? _errorAssigned;

  String _q = "";

  final List<Map<String, dynamic>> _openItems = [];
  final List<Map<String, dynamic>> _assignedItems = [];

  @override
  void initState() {
    super.initState();

    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    _fetchAll();

    _socket.on("panic:new", _onPanicNew);
    _socket.on("panic:assigned", _onPanicAssigned);

    _searchC.addListener(() {
      setState(() {
        _q = _searchC.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchC.dispose();

    _socket.off("panic:new");
    _socket.off("panic:assigned");

    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchOpenPanics(), _fetchAssignedPanics()]);
  }

  bool _isOpen(Map<String, dynamic> item) {
    final status = (item["status"] ?? "OPEN").toString().toUpperCase();
    return status == "OPEN";
  }

  bool _isAssigned(Map<String, dynamic> item) {
    final status = (item["status"] ?? "").toString().toUpperCase();
    return status == "ASSIGNED";
  }

  String _statusLabel(dynamic status) {
    final s = (status ?? "").toString().toUpperCase();

    if (s == "OPEN") return "Menunggu";
    if (s == "ASSIGNED") return "Diproses";
    if (s == "RESOLVED") return "Selesai";
    if (s == "CANCELLED") return "Dibatalkan";

    return s.isEmpty ? "-" : s;
  }

  Color _statusColor(dynamic status) {
    final s = (status ?? "").toString().toUpperCase();

    if (s == "OPEN") return Colors.red;
    if (s == "ASSIGNED") return Colors.orange;
    if (s == "RESOLVED") return Colors.green;
    if (s == "CANCELLED") return Colors.grey;

    return Colors.black54;
  }

  void _onPanicNew(dynamic payload) {
    final data = Map<String, dynamic>.from(payload);
    final pid = data["panicId"] ?? data["id"];

    final normalized = {...data, "status": data["status"] ?? "OPEN"};

    if (!_isOpen(normalized)) return;

    setState(() {
      final exists = _openItems.any((e) => (e["panicId"] ?? e["id"]) == pid);
      if (!exists) {
        _openItems.insert(0, normalized);
      }
    });
  }

  void _onPanicAssigned(dynamic payload) {
    final data = Map<String, dynamic>.from(payload);
    final pid = data["panicId"] ?? data["id"];

    setState(() {
      _openItems.removeWhere((e) => (e["panicId"] ?? e["id"]) == pid);
    });

    // Ambil ulang dari history supaya tab "Sedang Saya Proses" langsung update.
    _fetchAssignedPanics();
  }

  Future<void> _fetchOpenPanics() async {
    setState(() {
      _loadingOpen = true;
      _errorOpen = null;
    });

    try {
      final resp = await http.get(
        Uri.parse("${widget.baseUrl}/api/mobile/officer/panic/offered"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (resp.statusCode != 200) {
        setState(() {
          _errorOpen = "Gagal load panic masuk (${resp.statusCode})";
          _loadingOpen = false;
        });
        return;
      }

      final list = jsonDecode(resp.body) as List<dynamic>;

      final mapped = list
          .map((e) => Map<String, dynamic>.from(e))
          .map((e) => {...e, "status": e["status"] ?? "OPEN"})
          .where(_isOpen)
          .toList();

      mapped.sort((a, b) {
        final ad = (a["created_at"] ?? a["createdAt"] ?? "").toString();
        final bd = (b["created_at"] ?? b["createdAt"] ?? "").toString();
        return bd.compareTo(ad);
      });

      setState(() {
        _openItems
          ..clear()
          ..addAll(mapped);
        _loadingOpen = false;
      });
    } catch (e) {
      setState(() {
        _errorOpen = "Error: $e";
        _loadingOpen = false;
      });
    }
  }

  Future<void> _fetchAssignedPanics() async {
    setState(() {
      _loadingAssigned = true;
      _errorAssigned = null;
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
          _errorAssigned = "Gagal load panic diproses (${resp.statusCode})";
          _loadingAssigned = false;
        });
        return;
      }

      final list = jsonDecode(resp.body) as List<dynamic>;

      final mapped = list
          .map((e) => Map<String, dynamic>.from(e))
          .where(_isAssigned)
          .toList();

      mapped.sort((a, b) {
        final ad =
            (a["respondedAt"] ??
                    a["responded_at"] ??
                    a["updatedAt"] ??
                    a["updated_at"] ??
                    a["createdAt"] ??
                    a["created_at"] ??
                    "")
                .toString();

        final bd =
            (b["respondedAt"] ??
                    b["responded_at"] ??
                    b["updatedAt"] ??
                    b["updated_at"] ??
                    b["createdAt"] ??
                    b["created_at"] ??
                    "")
                .toString();

        return bd.compareTo(ad);
      });

      setState(() {
        _assignedItems
          ..clear()
          ..addAll(mapped);
        _loadingAssigned = false;
      });
    } catch (e) {
      setState(() {
        _errorAssigned = "Error: $e";
        _loadingAssigned = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> source) {
    if (_q.isEmpty) return source;

    return source.where((x) {
      final fromName = (x["fromName"] ?? x["citizen_name"] ?? "")
          .toString()
          .toLowerCase();

      final addr = (x["address"] ?? "").toString().toLowerCase();

      final pid = (x["panicId"] ?? x["id"] ?? "").toString().toLowerCase();

      final status = (x["status"] ?? "").toString().toLowerCase();

      return fromName.contains(_q) ||
          addr.contains(_q) ||
          pid.contains(_q) ||
          status.contains(_q);
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

  String _fmtTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return "-";

    try {
      final dt = DateTime.parse(value.toString()).toLocal();

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
      return value.toString();
    }
  }

  Future<void> _openOpenDetail(Map<String, dynamic> item) async {
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

    await _fetchAll();
  }

  Future<void> _openAssignedDetail(Map<String, dynamic> item) async {
    final pid = item["panicId"] ?? item["id"];

    if (pid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PanicHistoryDetailPage(
          token: widget.token,
          baseUrl: widget.baseUrl,
          panicId: (pid as num).toInt(),
        ),
      ),
    );

    await _fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Panic Dispatch Open"),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _fetchAll,
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh",
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.warning_amber_rounded), text: "Panic Masuk"),
              Tab(
                icon: Icon(Icons.pending_actions_rounded),
                text: "Sedang Saya Proses",
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchC,
                decoration: InputDecoration(
                  hintText: "Cari nama, alamat, atau ID...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
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
            Expanded(
              child: TabBarView(
                children: [
                  _buildPanicList(
                    loading: _loadingOpen,
                    error: _errorOpen,
                    items: _filterItems(_openItems),
                    emptyMessage: _q.isEmpty
                        ? "Belum ada panic yang masih menunggu respon."
                        : "Pencarian tidak ditemukan.",
                    timeLabel: "Masuk Pada",
                    onRefresh: _fetchOpenPanics,
                    onTap: _openOpenDetail,
                  ),
                  _buildPanicList(
                    loading: _loadingAssigned,
                    error: _errorAssigned,
                    items: _filterItems(_assignedItems),
                    emptyMessage: _q.isEmpty
                        ? "Belum ada panic yang sedang kamu proses."
                        : "Pencarian tidak ditemukan.",
                    timeLabel: "Direspon Pada",
                    onRefresh: _fetchAssignedPanics,
                    onTap: _openAssignedDetail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicList({
    required bool loading,
    required String? error,
    required List<Map<String, dynamic>> items,
    required String emptyMessage,
    required String timeLabel,
    required Future<void> Function() onRefresh,
    required Future<void> Function(Map<String, dynamic>) onTap,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _buildEmptyState(Icons.error_outline, error, Colors.red)
          : items.isEmpty
          ? _buildEmptyState(
              Icons.warning_amber_rounded,
              emptyMessage,
              Colors.black45,
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final x = items[i];

                final pid = x["panicId"] ?? x["id"];

                final fromName =
                    (x["fromName"] ?? x["citizen_name"] ?? "Tidak Diketahui")
                        .toString();

                final addr =
                    (x["address"] ??
                            "${_fmtCoord(x["lat"])}, ${_fmtCoord(x["lng"])}")
                        .toString();

                final statusRaw = (x["status"] ?? "OPEN").toString();

                final dist = _fmtDistance(x["distanceM"]);

                final timeValue = _fmtTime(
                  x["respondedAt"] ??
                      x["responded_at"] ??
                      x["createdAt"] ??
                      x["created_at"] ??
                      x["created"],
                );

                final statusText = _statusLabel(statusRaw);
                final statusColor = _statusColor(statusRaw);

                return Card(
                  color: AppColors.textMuted4,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onTap(x),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            children: [
                              _pill(Icons.route_outlined, "Jarak", dist),
                              const SizedBox(width: 10),
                              _pill(
                                Icons.access_time_rounded,
                                timeLabel,
                                timeValue,
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
    );
  }

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
