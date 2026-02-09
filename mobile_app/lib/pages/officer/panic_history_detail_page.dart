import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PanicHistoryDetailPage extends StatefulWidget {
  final String token;
  final String baseUrl;
  final int panicId;

  const PanicHistoryDetailPage({
    super.key,
    required this.token,
    required this.baseUrl,
    required this.panicId,
  });

  @override
  State<PanicHistoryDetailPage> createState() => _PanicHistoryDetailPageState();
}

class _PanicHistoryDetailPageState extends State<PanicHistoryDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
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
      String two(int v) => v.toString().padLeft(2, "0");
      return "${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
    } catch (_) {
      return iso;
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      final resp = await http.get(
        Uri.parse(
          "${widget.baseUrl}/api/mobile/officer/panic/history/${widget.panicId}",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (resp.statusCode != 200) {
        setState(() {
          _error = "Gagal load detail (${resp.statusCode})";
          _loading = false;
        });
        return;
      }

      final json = Map<String, dynamic>.from(jsonDecode(resp.body));
      setState(() {
        _data = json;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final web = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
      );
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF8B5A24);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Riwayat Panic"),
        backgroundColor: primary,
        actions: [
          IconButton(onPressed: _fetchDetail, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final x = _data!;
    final fromName = (x["fromName"] ?? "-").toString();
    final addr = (x["address"] ?? "-").toString();
    final status = (x["status"] ?? "-").toString();
    final createdAt = _fmtTime(x["createdAt"]?.toString());
    final respondedAt = _fmtTime(x["respondedAt"]?.toString());
    final resolvedAt = _fmtTime(x["resolvedAt"]?.toString());
    final dist = _fmtDistance(x["distanceM"]);

    final lat = (x["lat"] as num?)?.toDouble();
    final lng = (x["lng"] as num?)?.toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dari: $fromName",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Status: $status",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text("Lokasi: $addr"),
                if (lat != null && lng != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Koordinat: $lat, $lng",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _pill("Jarak saat dispatch", dist)),
                    const SizedBox(width: 10),
                    Expanded(child: _pill("Panic ID", "${widget.panicId}")),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _pill("Dibuat", createdAt)),
                    const SizedBox(width: 10),
                    Expanded(child: _pill("Di respon", respondedAt)),
                  ],
                ),
                const SizedBox(height: 10),
                _pill("Diselesaikan", resolvedAt),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (lat != null && lng != null)
                  ? () => _openMaps(lat, lng)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5A24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text(
                "BUKA LOKASI DI MAPS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
