import 'package:flutter/material.dart';

class PanicBannerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRespond;
  final VoidCallback onClose;
  final bool isTaking; // kalau lagi proses respond, disable tombol

  const PanicBannerCard({
    super.key,
    required this.data,
    required this.onRespond,
    required this.onClose,
    this.isTaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final fromName = (data['fromName'] ?? '-').toString();
    final address = data['address'];
    final lat = data['lat'];
    final lng = data['lng'];
    final distanceM = data['distanceM'];

    final locText = (address != null && address.toString().trim().isNotEmpty)
        ? address.toString()
        : '${lat ?? '-'}, ${lng ?? '-'}';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PANGGILAN DARURAT!!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Dari : $fromName",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Lokasi : $locText",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Jarak : ${distanceM ?? '-'} m",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isTaking ? null : onRespond,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB71C1C),
                      disabledBackgroundColor: Colors.white70,
                      disabledForegroundColor: const Color(0xFFB71C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isTaking ? "MEMBUKA..." : "DETAIL"),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
