import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/background_zone_service.dart';
import 'crime_incident.dart';
import 'zona_bahaya_detail_page.dart';
import 'package:mobile_app/config/api_config.dart';

// SAMAKAN base URL dengan yang lain (login, lapor cepat, dll)
// const String apiBaseUrl = 'http://10.121.204.17:3000/api';

/// helper buat convert dynamic -> double aman (bisa String / num)
double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

Color _hexToColor(String? hex, {Color fallback = Colors.red}) {
  if (hex == null || hex.trim().isEmpty) return fallback;

  var h = hex.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h'; // add alpha
  if (h.length != 8) return fallback;

  return Color(int.parse(h, radix: 16));
}

class CrimeMapPage extends StatefulWidget {
  const CrimeMapPage({super.key});

  @override
  State<CrimeMapPage> createState() => _CrimeMapPageState();
}

class _CrimeMapPageState extends State<CrimeMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final _distance = const lat_lng.Distance();
  List<CrimeIncident> _insideZones = [];

  void _recalcInsideZones() {
    if (_currentLatLng == null) return;

    final inside = _incidents.where((z) {
      if (z.radiusMeter <= 0) return false;
      final d = _distance.as(
        lat_lng.LengthUnit.Meter,
        _currentLatLng!,
        z.position,
      );
      return d <= z.radiusMeter;
    }).toList();

    setState(() => _insideZones = inside);
  }

  // ⬇️ sekarang list-nya kosong, nanti diisi dari backend
  List<CrimeIncident> _incidents = [];

  CrimeIncident? _selectedIncident;

  bool _isLocLoading = false;
  bool _isSearching = false;
  bool _isIncidentLoading = false;

  lat_lng.LatLng? _currentLatLng;
  final Map<String, String> _addressCache = {};
  bool _isAddressLoading = false;

  @override
  void initState() {
    super.initState();
    _moveToCurrentLocation();
    _loadIncidentsFromBackend();
  }

  // ================== LOAD DATA DARI BACKEND ==================
  Future<void> _loadIncidentsFromBackend() async {
    setState(() => _isIncidentLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null) {
        _showSnack('Token tidak ditemukan, silakan login ulang.');
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
        headers: {'Authorization': 'Bearer $token'},
      );
      // final url = Uri.parse('${ApiConfig.baseUrl}/mobile/laporan-cepat/me');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] as List;

        // 1. Siapkan data mentah untuk disimpan
        List<Map<String, dynamic>> rawZonesForService = data.map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();

        // 2. Simpan ke Shared Preferences via Service
        await BackgroundZoneService.saveZones(rawZonesForService);

        await BackgroundZoneService.start();

        debugPrint(
          "✅ Data zona berhasil disinkronkan ke Background Service: ${rawZonesForService.length} zona",
        );

        final incidents = data.map<CrimeIncident>((z) {
          final status = (z['status_zona'] ?? 'pending')
              .toString()
              .toLowerCase();
          final nama = (z['nama_zona'] ?? 'Zona tanpa nama').toString();
          final deskripsi = (z['deskripsi'] ?? '').toString();
          final tgl = z['tanggal_kejadian']?.toString() ?? '';
          final jamRaw = z['waktu_kejadian']?.toString() ?? '';

          final lat = _toDouble(z['latitude']);
          final lon = _toDouble(z['longitude']);

          // ✅ ambil radius & warna
          final radius = _toDouble(z['radius_meter'] ?? 0);
          final warnaHex = z['warna_hex']?.toString();
          final zoneColor = _hexToColor(warnaHex);

          final risk = (z['tingkat_risiko'] ?? 'sedang').toString();
          final idLaporanSumber = z['id_laporan_sumber']?.toString();
          final tglKejadian = z['tanggal_kejadian']?.toString();
          final wktKejadian = z['waktu_kejadian']?.toString();
          final jam = (wktKejadian != null && wktKejadian.length >= 5)
              ? wktKejadian.substring(0, 5)
              : '';

          // status color untuk badge (pending/orange, approve/red)
          Color statusColor;
          if (status == 'approve' ||
              status == 'approved' ||
              status == 'aktif') {
            statusColor = Colors.red;
          } else if (status == 'nonaktif') {
            statusColor = Colors.grey;
          } else {
            statusColor = Colors.orange; // pending
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
            riskLevel: risk,
            reportSourceId: idLaporanSumber,
            tanggalKejadian: tglKejadian,
            waktuKejadian: jam,
          );
        }).toList();

        setState(() {
          _incidents = incidents;
        });
        _recalcInsideZones();
      } else {
        debugPrint('load zona gagal: ${res.statusCode} ${res.body}');
        _showSnack('Gagal mengambil data zona (${res.statusCode})');
      }
    } catch (e) {
      debugPrint('load zona error: $e');
      _showSnack('Terjadi kesalahan saat load data zona: $e');
    } finally {
      if (mounted) {
        setState(() => _isIncidentLoading = false);
      }
    }
  }

  // ================== IZIN & LOKASI USER ==================
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location service belum aktif. Aktifkan GPS dulu ya.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack(
          'Izin lokasi ditolak. Fitur maps tidak bisa mendeteksi posisi kamu.',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack(
        'Izin lokasi diblokir permanen. Buka Pengaturan > Aplikasi dan izinkan lokasi.',
      );
      return false;
    }

    return true;
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _isLocLoading = true);

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() => _isLocLoading = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final target = lat_lng.LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentLatLng = target;
      });
      _recalcInsideZones();

      _mapController.move(target, 16);
    } catch (e) {
      debugPrint('getCurrentPosition error: $e');
      _showSnack('Gagal ambil lokasi: $e');
    } finally {
      setState(() => _isLocLoading = false);
    }
  }

  // ================== SEARCH LOKASI (OPENSTREETMAP) ==================
  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=1',
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'sigap-mobile-app/1.0 (example@mail.com)'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isEmpty) {
          _showSnack('Lokasi tidak ditemukan, coba kata kunci lain.');
        } else {
          final first = data[0];
          final lat = double.parse(first['lat'] as String);
          final lon = double.parse(first['lon'] as String);

          final target = lat_lng.LatLng(lat, lon);
          _mapController.move(target, 15);
        }
      } else {
        _showSnack('Gagal mencari lokasi (${res.statusCode}).');
      }
    } catch (e) {
      _showSnack('Error saat mencari lokasi: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showSnack(String msg) {
    // Kalau state-nya sudah di-dispose, jangan ngapa-ngapain
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================== REVERSE GEOCODE (LAT/LONG → ALAMAT) ==================
  Future<void> _loadAddressForIncident(CrimeIncident incident) async {
    final key = incident.id;

    if (_addressCache.containsKey(key)) return;

    setState(() => _isAddressLoading = true);

    try {
      final lat = incident.position.latitude;
      final lon = incident.position.longitude;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=$lat'
        '&lon=$lon'
        '&zoom=18'
        '&addressdetails=1',
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'sigap-mobile-app/1.0 (example@mail.com)'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && mounted) {
          setState(() {
            _addressCache[key] = displayName;
          });
        }
      } else {
        debugPrint('Reverse geocode gagal: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAddressLoading = false);
      }
    }
  }

  // ================== MARKER BUILDER ==================
  Widget _buildIncidentMarker(CrimeIncident incident) {
    final statusLower = incident.status.toLowerCase();

    final bool isPending = statusLower.contains('pending');

    if (isPending) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.question_mark, color: Colors.red, size: 30),
      );
    } else {
      return const Icon(Icons.location_on, size: 40, color: Colors.red);
    }
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5A24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Maps Lokasi Kejahatan',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: _insideZones.isEmpty
                ? _StatusChip(
                    text: "✅ Kamu aman (di luar zona bahaya)",
                    bg: Colors.green,
                  )
                : _StatusChip(
                    text:
                        "⚠️ Kamu masuk zona: ${_insideZones.map((e) => e.title).take(2).join(", ")}",
                    bg: Colors.red,
                  ),
          ),

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const lat_lng.LatLng(-6.2, 106.816666),
              initialZoom: 14,
              onTap: (_, __) {
                setState(() => _selectedIncident = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.mobile_app',
              ),
              CircleLayer(
                circles: _incidents
                    .where((i) => i.radiusMeter > 0)
                    .map(
                      (i) => CircleMarker(
                        point: i.position,
                        radius: i.radiusMeter,
                        useRadiusInMeter:
                            true, // penting biar meter, bukan pixel
                        color: i.zoneColor.withOpacity(0.18), // fill
                        borderColor: i.zoneColor.withOpacity(0.9),
                        borderStrokeWidth: 2,
                      ),
                    )
                    .toList(),
              ),
              MarkerLayer(
                markers: [
                  if (_currentLatLng != null)
                    Marker(
                      point: _currentLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                  ..._incidents.map(
                    (incident) => Marker(
                      point: incident.position,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIncident = incident;
                          });
                          _loadAddressForIncident(incident);
                        },
                        child: _buildIncidentMarker(incident),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // SEARCH BAR
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari lokasi (contoh: Medan, Sumatera Utara)',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchLocation(),
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _searchLocation,
                    ),
                ],
              ),
            ),
          ),

          // LOADING LOKASI USER
          if (_isLocLoading)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Mencari Lokasi Anda Saat Ini...'),
                    ],
                  ),
                ),
              ),
            ),

          // LOADING DATA ZONA
          if (_isIncidentLoading && _incidents.isEmpty)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Memuat data kejahatan...'),
                    ],
                  ),
                ),
              ),
            ),

          // CARD DETAIL
          if (_selectedIncident != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _IncidentDetailCard(
                incident: _selectedIncident!,
                address: _addressCache[_selectedIncident!.id],
                isAddressLoading: _isAddressLoading,
                onClose: () {
                  setState(() => _selectedIncident = null);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color bg;
  const _StatusChip({required this.text, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ===== CARD DETAIL (CrimeIncident pakai model bersama) =====
class _IncidentDetailCard extends StatelessWidget {
  final CrimeIncident incident;
  final String? address;
  final bool isAddressLoading;
  final VoidCallback onClose;

  const _IncidentDetailCard({
    required this.incident,
    required this.address,
    required this.isAddressLoading,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    incident.title.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Status : ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Expanded(
                  child: Text(
                    incident.status,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Waktu  : ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Expanded(
                  child: Text(
                    incident.time,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lokasi : ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Expanded(
                  child: isAddressLoading && address == null
                      ? Row(
                          children: const [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Mengambil alamat...',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        )
                      : Text(
                          address ??
                              'Koordinat: '
                                  '${incident.position.latitude.toStringAsFixed(5)}, '
                                  '${incident.position.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Deskripsi :',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(incident.description, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZonaBahayaDetailPage(incident: incident),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5A24),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Detail Kejadian',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
