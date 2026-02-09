import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/pages/panic/panic_waiting_page.dart';

class PanicHoldButton extends StatefulWidget {
  final String token;
  final String baseUrl; // root: http://IP:3001 (tanpa /api)

  const PanicHoldButton({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<PanicHoldButton> createState() => _PanicHoldButtonState();
}

class _PanicHoldButtonState extends State<PanicHoldButton> {
  Timer? _timer;
  double _progress = 0.0;
  bool _sending = false;

  void _startHold() {
    if (_sending) return;
    _timer?.cancel();
    setState(() => _progress = 0);

    const totalMs = 3000;
    const tickMs = 60;
    int elapsed = 0;

    _timer = Timer.periodic(const Duration(milliseconds: tickMs), (t) async {
      elapsed += tickMs;
      setState(() => _progress = elapsed / totalMs);

      if (elapsed >= totalMs) {
        t.cancel();
        await _sendPanic();
      }
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    setState(() => _progress = 0);
  }

  Future<void> _sendPanic() async {
    try {
      setState(() => _sending = true);

      // permission lokasi
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak")));
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final resp = await http.post(
        Uri.parse("${widget.baseUrl}/api/mobile/panic"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "lat": pos.latitude,
          "lng": pos.longitude,
          "address": null, // optional (nanti bisa reverse geocode)
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final int panicId = (json["panicId"] as num).toInt();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("active_panic_id", panicId);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PanicWaitingPage(
              token: widget.token,
              baseUrl: widget.baseUrl,
              panicId: panicId,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⏳ Menunggu respon officer...")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal kirim panic: ${resp.body}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _cancelHold();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: () => _cancelHold(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                disabledBackgroundColor: const Color(0xFFC62828),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
              ),
              child: Text(
                _sending ? "MENGIRIM..." : "PANIC BUTTON",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 14,
            right: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                minHeight: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
