import 'package:flutter/material.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'citizen_panic_detail_page.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    _checkStatusOnce();
    // polling tiap 2 detik
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkStatusOnce();
    });

    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    // ✅ debug penting banget
    _socket.on("socket:ready", (d) {
      debugPrint("✅ [citizen socket ready] $d");
      if (!mounted) return;
      setState(() => _statusText = "✅ Tersambung. Menunggu officer respon...");
    });

    // socket_io_client event default
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

    // optional event (kalau backend emit)
    _socket.on("panic:waiting", (payload) {
      final data = Map<String, dynamic>.from(payload);
      final pid = (data["panicId"] as num?)?.toInt();
      if (pid == widget.panicId && mounted) {
        setState(
          () => _statusText = (data["message"] ?? _statusText).toString(),
        );
      }
    });

    // ✅ event utama
    _socket.on("panic:responded", (payload) async {
      final data = Map<String, dynamic>.from(payload);

      final pidRaw = data["panicId"];
      final pid = (pidRaw is num) ? pidRaw.toInt() : int.tryParse("$pidRaw");

      if (pid == null || pid != widget.panicId) return;

      final officer = Map<String, dynamic>.from(data["officer"]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("active_panic_id", pid);

      if (!mounted) return;

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

    _socket.on("panic:resolved", (payload) async {
      final data = Map<String, dynamic>.from(payload);
      final pid = (data["panicId"] as num?)?.toInt();
      if (pid != widget.panicId) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("active_panic_id");

      if (!mounted) return;
      Navigator.pop(context);
    });
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
        final officer = {
          "id": json["assignedOfficerId"],
          "nama": json["assignedOfficerName"],
        };

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
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket.disconnect();
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
