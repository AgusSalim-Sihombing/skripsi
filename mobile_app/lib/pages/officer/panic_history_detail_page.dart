import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/theme/app_theme.dart';
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
  bool _resolving = false;

  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _fmtDistance(dynamic distanceM) {
    final n = _toDouble(distanceM);

    if (n == null) return "-";
    if (n < 1000) return "${n.toStringAsFixed(0)} m";

    return "${(n / 1000).toStringAsFixed(2)} km";
  }

  String _fmtTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return "-";

    final text = value.toString().trim();

    try {
      DateTime dt;

      if (text.contains("T") || text.endsWith("Z")) {
        dt = DateTime.parse(text).toLocal();
      } else {
        dt = DateTime.parse(text.replaceFirst(" ", "T"));
      }

      String two(int v) => v.toString().padLeft(2, "0");

      return "${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
    } catch (_) {
      return text;
    }
  }

  String _statusLabel(dynamic value) {
    final status = (value ?? "-").toString().toUpperCase();

    if (status == "OPEN") return "Menunggu";
    if (status == "ASSIGNED") return "Diproses";
    if (status == "RESOLVED") return "Selesai";
    if (status == "CANCELLED") return "Dibatalkan";

    return status;
  }

  Color _statusColor(dynamic value) {
    final status = (value ?? "").toString().toUpperCase();

    if (status == "OPEN") return Colors.red;
    if (status == "ASSIGNED") return Colors.orange;
    if (status == "RESOLVED") return Colors.green;
    if (status == "CANCELLED") return Colors.grey;

    return Colors.black54;
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
          "ngrok-skip-browser-warning": "true",
        },
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(resp.body);
      } catch (_) {
        decoded = null;
      }

      if (resp.statusCode != 200) {
        final msg = decoded is Map
            ? decoded["message"] ?? "Gagal load detail (${resp.statusCode})"
            : "Gagal load detail (${resp.statusCode})";

        setState(() {
          _error = msg.toString();
          _loading = false;
        });
        return;
      }

      setState(() {
        _data = Map<String, dynamic>.from(decoded);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  Future<void> _resolvePanic() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Selesaikan Panic?"),
        content: const Text(
          "Pastikan penanganan panic sudah selesai sebelum menekan tombol ini.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Ya, Selesaikan"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _resolving = true;
    });

    try {
      final resp = await http.post(
        Uri.parse(
          "${widget.baseUrl}/api/mobile/officer/panic/${widget.panicId}/resolve",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
          "ngrok-skip-browser-warning": "true",
        },
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(resp.body);
      } catch (_) {
        decoded = null;
      }

      if (resp.statusCode != 200) {
        final msg = decoded is Map
            ? decoded["message"] ?? "Gagal menyelesaikan panic"
            : "Gagal menyelesaikan panic";

        throw Exception(msg);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Panic berhasil diselesaikan")),
      );

      await _fetchDetail();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $e")));
    } finally {
      if (mounted) {
        setState(() {
          _resolving = false;
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Detail Panic"),
        actions: [
          IconButton(
            onPressed: _loading || _resolving ? null : _fetchDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final x = _data!;

    final fromName = (x["fromName"] ?? "-").toString();
    final addr = (x["address"] ?? "-").toString();

    final statusRaw = (x["status"] ?? "-").toString().toUpperCase();
    final statusText = _statusLabel(statusRaw);
    final statusColor = _statusColor(statusRaw);

    final createdAt = _fmtTime(x["createdAt"] ?? x["created_at"]);
    final respondedAt = _fmtTime(x["respondedAt"] ?? x["responded_at"]);
    final resolvedAt = _fmtTime(x["resolvedAt"] ?? x["resolved_at"]);

    final dist = _fmtDistance(x["distanceM"] ?? x["distance_m"]);

    final lat = _toDouble(x["lat"]);
    final lng = _toDouble(x["lng"]);

    final canResolve = statusRaw == "ASSIGNED";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.textMuted4,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Panic ID: #${widget.panicId}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  "Dari: $fromName",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Lokasi: $addr",
                  style: const TextStyle(color: Colors.black87, height: 1.4),
                ),

                if (lat != null && lng != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Koordinat: $lat, $lng",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _pill("Jarak saat dispatch", dist)),
                    const SizedBox(width: 10),
                    Expanded(child: _pill("Status", statusText)),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: _pill("Dibuat", createdAt)),
                    const SizedBox(width: 10),
                    Expanded(child: _pill("Direspon", respondedAt)),
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
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text(
                "BUKA LOKASI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          if (canResolve) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resolving ? null : _resolvePanic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _resolving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  _resolving ? "MENYELESAIKAN..." : "SELESAIKAN PANIC",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ] else if (statusRaw == "RESOLVED") ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.25)),
              ),
              child: const Text(
                "✅ Panic ini sudah diselesaikan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
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
