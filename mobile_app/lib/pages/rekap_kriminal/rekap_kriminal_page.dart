import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:mobile_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_app/config/api_config.dart';
import 'package:mobile_app/pages/maps_lokasi_kejahatan/crime_incident.dart';
import 'package:mobile_app/pages/maps_lokasi_kejahatan/zona_bahaya_detail_page.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value) ?? 0;
  return 0;
}

Color _hexToColor(String? hex, {Color fallback = Colors.red}) {
  if (hex == null || hex.trim().isEmpty) return fallback;
  var h = hex.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  return Color(int.parse(h, radix: 16));
}

bool _isApprovedStatus(String s) {
  final v = s.toLowerCase();
  return v == "approve" || v == "approved" || v == "aktif";
}

class RekapKriminalPage extends StatefulWidget {
  const RekapKriminalPage({super.key});

  @override
  State<RekapKriminalPage> createState() => _RekapKriminalPageState();
}

class _RekapKriminalPageState extends State<RekapKriminalPage> {
  bool _loading = false;
  String _err = "";
  List<CrimeIncident> _items = [];

  // filter: all / pending / approved
  String _filter = "all";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = "";
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => _err = "Token tidak ditemukan. Silakan login ulang.");
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) {
        setState(() => _err = "Gagal load data (${res.statusCode})");
        return;
      }

      final decoded = jsonDecode(res.body);
      final List data = (decoded['data'] ?? []) as List;

      final list = data.map<CrimeIncident>((z) {
        final status = (z['status_zona'] ?? 'pending').toString().toLowerCase();
        final nama = (z['nama_zona'] ?? 'Zona tanpa nama').toString();
        final deskripsi = (z['deskripsi'] ?? '').toString();

        final tgl = z['tanggal_kejadian']?.toString() ?? '';
        final jamRaw = z['waktu_kejadian']?.toString() ?? '';
        final jam = jamRaw.length >= 5 ? jamRaw.substring(0, 5) : jamRaw;

        final lat = _toDouble(z['latitude']);
        final lon = _toDouble(z['longitude']);

        final radius = _toDouble(z['radius_meter'] ?? 0);
        final warnaHex = z['warna_hex']?.toString();
        final zoneColor = _hexToColor(warnaHex);

        final riskLevel = (z['tingkat_risiko'] ?? 'sedang').toString();
        final reportSourceId = z['id_laporan_sumber']?.toString();

        // buat statusColor (badge)
        Color statusColor;
        if (_isApprovedStatus(status)) {
          statusColor = Colors.green;
        } else if (status == 'nonaktif') {
          statusColor = Colors.grey;
        } else {
          statusColor = Colors.orange;
        }

        return CrimeIncident(
          id: z['id_zona'].toString(),
          title: nama,
          status: status,
          time: jam.isNotEmpty ? '$tgl $jam' : tgl,
          description: deskripsi,
          statusColor: statusColor,
          position: lat_lng.LatLng(lat, lon),
          radiusMeter: radius,
          zoneColor: zoneColor,

          // tambahan sesuai model kamu
          riskLevel: riskLevel,
          reportSourceId: reportSourceId,
          tanggalKejadian: tgl.isEmpty ? null : tgl,
          waktuKejadian: jam.isEmpty ? null : jam,
        );
      }).toList();

      setState(() => _items = list);
    } catch (e) {
      setState(() => _err = "Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CrimeIncident> get _filteredItems {
    if (_filter == "pending") {
      return _items.where((e) => !_isApprovedStatus(e.status)).toList();
    }
    if (_filter == "approved") {
      return _items.where((e) => _isApprovedStatus(e.status)).toList();
    }
    return _items;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Kriminal", style: TextStyle(fontSize: 16)),
        backgroundColor: isDark ? AppColors.bgPrimary : const Color(0xFFF4F4F4),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _FilterChip(
                  label: "Semua",
                  active: _filter == "all",
                  onTap: () => setState(() => _filter = "all"),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: "Pending",
                  active: _filter == "pending",
                  onTap: () => setState(() => _filter = "pending"),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: "Approved",
                  active: _filter == "approved",
                  onTap: () => setState(() => _filter = "approved"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _err.isNotEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _err,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    )
                  : list.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text("Belum ada data zona.")),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final it = list[i];
                        final approved = _isApprovedStatus(it.status);

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ZonaBahayaDetailPage(incident: it),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: _ZonaFotoThumb(idZona: it.id),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _MiniChip(
                                            text: approved
                                                ? "APPROVED"
                                                : "PENDING",
                                            bg: approved
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          _MiniChip(
                                            text: "Risiko: ${it.riskLevel}",
                                            bg: Colors.blueGrey,
                                          ),
                                          _MiniChip(
                                            text:
                                                "Radius: ${it.radiusMeter.toStringAsFixed(0)}m",
                                            bg: Colors.black87,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        it.time.isEmpty ? "-" : it.time,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${it.position.latitude.toStringAsFixed(5)}, "
                                        "${it.position.longitude.toStringAsFixed(5)}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B5A24) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color bg;

  const _MiniChip({required this.text, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ZonaFotoThumb extends StatefulWidget {
  final String idZona;
  const _ZonaFotoThumb({required this.idZona});

  @override
  State<_ZonaFotoThumb> createState() => _ZonaFotoThumbState();
}

class _ZonaFotoThumbState extends State<_ZonaFotoThumb> {
  Uint8List? _bytes;
  bool _loading = true;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  Future<void> _loadFoto() async {
    setState(() => _loading = true);

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _bytes = null;
          _loading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/mobile/zona-bahaya/${widget.idZona}/foto',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() => _bytes = res.bodyBytes);
      } else {
        setState(() => _bytes = null);
      }
    } catch (_) {
      setState(() => _bytes = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFoto();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_bytes == null) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_not_supported, color: Colors.grey.shade600),
      );
    }

    return Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true);
  }
}
