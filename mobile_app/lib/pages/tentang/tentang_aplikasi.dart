import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // fallback: ga usah throw biar gak bikin crash
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF8B5A24);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tentang Aplikasi", style: TextStyle(fontSize: 16)),
        // backgroundColor: primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SIGAP",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Sistem Informasi & Geofencing Alert Kejahatan Publik",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ABOUT
            _SectionCard(
              title: "Apa itu SIGAP?",
              icon: Icons.info_outline_rounded,
              child: const Text(
                "SIGAP adalah aplikasi yang membantu masyarakat dan petugas memantau area rawan kejahatan, "
                "melakukan pelaporan cepat, serta menerima notifikasi saat berada di radius zona bahaya. "
                "Tujuannya: bikin respon lebih cepat, info lebih jelas, dan lingkungan lebih aman.",
                style: TextStyle(fontSize: 13, height: 1.45),
              ),
            ),

            const SizedBox(height: 12),

            // FEATURES
            _SectionCard(
              title: "Fitur Utama",
              icon: Icons.star_outline_rounded,
              child: Column(
                children: const [
                  _Bullet(text: "Peta Zona Bahaya (pending & approved)"),
                  _Bullet(text: "Detail kejadian + foto bukti (jika tersedia)"),
                  _Bullet(text: "Voting validasi zona untuk bantu verifikasi"),
                  _Bullet(text: "Peringatan ketika masuk radius zona bahaya"),
                  _Bullet(text: "Laporan cepat sebagai sumber pembuatan zona"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // HOW IT WORKS
            _SectionCard(
              title: "Cara Kerja Singkat",
              icon: Icons.route_rounded,
              child: Column(
                children: const [
                  _StepRow(
                    num: "1",
                    text:
                        "Masyarakat membuat laporan cepat + bukti foto (opsional).",
                  ),
                  _StepRow(
                    num: "2",
                    text:
                        "Admin meninjau laporan lalu bisa buat zona bahaya dari laporan tersebut.",
                  ),
                  _StepRow(
                    num: "3",
                    text:
                        "Pengguna bisa voting saat status zona masih PENDING.",
                  ),
                  _StepRow(
                    num: "4",
                    text:
                        "Saat pengguna masuk radius, aplikasi memberi peringatan secara otomatis.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // PRIVACY
            _SectionCard(
              title: "Privasi & Keamanan",
              icon: Icons.lock_outline_rounded,
              child: const Text(
                "SIGAP hanya memakai izin lokasi untuk kebutuhan peta, deteksi radius zona, dan akurasi informasi. "
                "Data yang tersimpan digunakan untuk operasional sistem dan proses validasi, "
                "bukan untuk diperjualbelikan. "
                "Kalau kamu memilih anonim saat melapor, identitas kamu tidak ditampilkan ke publik.",
                style: TextStyle(fontSize: 13, height: 1.45),
              ),
            ),

            const SizedBox(height: 12),

            // SUPPORT / CONTACT
            _SectionCard(
              title: "Bantuan & Kontak",
              icon: Icons.support_agent_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kalau nemu bug, data zona kurang sesuai, atau butuh bantuan penggunaan:",
                    style: TextStyle(fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionChip(
                        label: "Email Support",
                        icon: Icons.email_outlined,
                        onTap: () => _openUrl("mailto:support@sigap.app"),
                      ),
                      _ActionChip(
                        label: "Website",
                        icon: Icons.public,
                        onTap: () => _openUrl("https://example.com"),
                      ),
                      _ActionChip(
                        label: "FAQ",
                        icon: Icons.help_outline_rounded,
                        onTap: () => _openUrl("https://example.com/faq"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Catatan: ganti link/Email di atas sesuai kebutuhan project kamu ya.",
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // FOOTER
            Text(
              "Versi 1.0.0 • © ${DateTime.now().year} SIGAP",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // const primary = Color(0xFF8B5A24);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String num;
  final String text;

  const _StepRow({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF8B5A24);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35 , color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
