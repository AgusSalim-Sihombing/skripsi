import 'dart:async';
import 'dart:convert';
import 'package:mobile_app/pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'citizen_panic_detail_page.dart';

class PanicWaitingPage extends StatefulWidget {
  final String token;
  final String baseUrl; // root
  final int panicId;

  const PanicWaitingPage({
    super.key,
    required this.token,
    required this.baseUrl,
    required this.panicId,
  });

  @override
  State<PanicWaitingPage> createState() => _PanicWaitingPageState();
}

class _PanicWaitingPageState extends State<PanicWaitingPage> {
  final SocketService _socket = SocketService();
  String _statusText = "⏳ Menunggu respon officer...";
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    // polling tiap 2 detik (fallback kalau socket miss)
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkStatusOnce();
    });
    _checkStatusOnce();

    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    _socket.on("socket:ready", (d) {
      debugPrint("✅ [citizen socket ready] $d");
      if (!mounted) return;
      setState(() => _statusText = "✅ Tersambung. Menunggu officer respon...");
    });

    _socket.on("connect_error", (e) {
      debugPrint("❌ [citizen connect_error] $e");
      if (!mounted) return;
      setState(() => _statusText = "❌ Gagal konek socket. Cek IP/port server.");
    });

    _socket.on("disconnect", (reason) {
      debugPrint("⚠️ [citizen disconnected] $reason");
      if (!mounted) return;
      setState(
        () => _statusText = "⚠️ Koneksi terputus. Nyoba nyambung lagi...",
      );
    });

    // event utama
    _socket.on("panic:responded", (payload) async {
      final data = Map<String, dynamic>.from(payload);

      final pidRaw = data["panicId"];
      final pid = (pidRaw is num) ? pidRaw.toInt() : int.tryParse("$pidRaw");
      if (pid == null || pid != widget.panicId) return;

      final officer = Map<String, dynamic>.from(data["officer"]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("active_panic_id", pid);

      if (!mounted) return;

      _pollTimer?.cancel();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CitizenPanicDetailPage(
            token: widget.token,
            baseUrl: widget.baseUrl,
            panicId: pid,
            officer: officer,
          ),
        ),
      );
    });

    // officer selesai -> balik home
    _socket.on("panic:resolved", (payload) async {
      final data = Map<String, dynamic>.from(payload);
      final pidRaw = data["panicId"];
      final pid = (pidRaw is num) ? pidRaw.toInt() : int.tryParse("$pidRaw");
      if (pid == null || pid != widget.panicId) return;

      await _goLanding();
    });
  }

  Future<void> _goLanding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("active_panic_id");
    final username = prefs.getString("username") ?? "User";

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LandingPage(
          username: username,
          token: widget.token,
          baseUrl: widget.baseUrl,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _checkStatusOnce() async {
    try {
      final resp = await http.get(
        Uri.parse("${widget.baseUrl}/api/mobile/panic/${widget.panicId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (resp.statusCode != 200) return;

      final json = jsonDecode(resp.body);
      final status = (json["status"] ?? "").toString();

      if (!mounted) return;

      if (status == "ASSIGNED") {
        // ✅ bawa lastLat/lastLng dari API biar citizen map langsung hidup
        final officer = {
          "id": json["assignedOfficerId"],
          "nama": json["assignedOfficerName"],
          "lastLat": json["officerLastLat"],
          "lastLng": json["officerLastLng"],
        };

        _pollTimer?.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CitizenPanicDetailPage(
              token: widget.token,
              baseUrl: widget.baseUrl,
              panicId: widget.panicId,
              officer: officer,
            ),
          ),
        );
      } else if (status == "RESOLVED") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("active_panic_id");

        _pollTimer?.cancel();
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();

    _socket.off("socket:ready");
    _socket.off("connect_error");
    _socket.off("disconnect");
    _socket.off("panic:responded");
    _socket.off("panic:resolved");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menunggu Respon"),
        backgroundColor: const Color(0xFF8B5A24),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Panic ID: ${widget.panicId}",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
