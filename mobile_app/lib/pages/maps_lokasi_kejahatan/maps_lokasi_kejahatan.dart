// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart' as lat_lng;
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:mobile_app/services/background_zone_service.dart';
// import 'crime_incident.dart';
// import 'zona_bahaya_detail_page.dart';
// import 'package:mobile_app/config/api_config.dart';

// // SAMAKAN base URL dengan yang lain (login, lapor cepat, dll)
// // const String apiBaseUrl = 'http://10.121.204.17:3000/api';

// /// helper buat convert dynamic -> double aman (bisa String / num)
// double _toDouble(dynamic value) {
//   if (value == null) return 0;
//   if (value is num) return value.toDouble();
//   if (value is String && value.isNotEmpty) {
//     return double.tryParse(value) ?? 0;
//   }
//   return 0;
// }

// Color _hexToColor(String? hex, {Color fallback = Colors.red}) {
//   if (hex == null || hex.trim().isEmpty) return fallback;

//   var h = hex.trim().replaceAll('#', '');
//   if (h.length == 6) h = 'FF$h'; // add alpha
//   if (h.length != 8) return fallback;

//   return Color(int.parse(h, radix: 16));
// }

// class CrimeMapPage extends StatefulWidget {
//   const CrimeMapPage({super.key});

//   @override
//   State<CrimeMapPage> createState() => _CrimeMapPageState();
// }

// class _CrimeMapPageState extends State<CrimeMapPage> {
//   final MapController _mapController = MapController();
//   final TextEditingController _searchController = TextEditingController();
//   final _distance = const lat_lng.Distance();
//   List<CrimeIncident> _insideZones = [];

//   void _recalcInsideZones() {
//     if (_currentLatLng == null) return;

//     final inside = _incidents.where((z) {
//       if (z.radiusMeter <= 0) return false;
//       final d = _distance.as(
//         lat_lng.LengthUnit.Meter,
//         _currentLatLng!,
//         z.position,
//       );
//       return d <= z.radiusMeter;
//     }).toList();

//     setState(() => _insideZones = inside);
//   }

//   // ⬇️ sekarang list-nya kosong, nanti diisi dari backend
//   List<CrimeIncident> _incidents = [];

//   CrimeIncident? _selectedIncident;

//   bool _isLocLoading = false;
//   bool _isSearching = false;
//   bool _isIncidentLoading = false;

//   lat_lng.LatLng? _currentLatLng;
//   final Map<String, String> _addressCache = {};
//   bool _isAddressLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _moveToCurrentLocation();
//     _loadIncidentsFromBackend();
//   }

//   // ================== LOAD DATA DARI BACKEND ==================
//   Future<void> _loadIncidentsFromBackend() async {
//     setState(() => _isIncidentLoading = true);

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('user_token');

//       if (token == null) {
//         _showSnack('Token tidak ditemukan, silakan login ulang.');
//         return;
//       }

//       final res = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       // final url = Uri.parse('${ApiConfig.baseUrl}/mobile/laporan-cepat/me');

//       if (res.statusCode == 200) {
//         final decoded = jsonDecode(res.body);
//         final List data = decoded['data'] as List;

//         // 1. Siapkan data mentah untuk disimpan
//         List<Map<String, dynamic>> rawZonesForService = data.map((e) {
//           return Map<String, dynamic>.from(e);
//         }).toList();

//         // 2. Simpan ke Shared Preferences via Service
//         await BackgroundZoneService.saveZones(rawZonesForService);

//         await BackgroundZoneService.start();

//         debugPrint(
//           "Data zona berhasil disinkronkan ke Background Service: ${rawZonesForService.length} zona",
//         );

//         final incidents = data.map<CrimeIncident>((z) {
//           final status = (z['status_zona'] ?? 'pending')
//               .toString()
//               .toLowerCase();
//           final nama = (z['nama_zona'] ?? 'Zona tanpa nama').toString();
//           final deskripsi = (z['deskripsi'] ?? '').toString();
//           final tgl = z['tanggal_kejadian']?.toString() ?? '';
//           final jamRaw = z['waktu_kejadian']?.toString() ?? '';

//           final lat = _toDouble(z['latitude']);
//           final lon = _toDouble(z['longitude']);

//           // ✅ ambil radius & warna
//           final radius = _toDouble(z['radius_meter'] ?? 0);
//           final warnaHex = z['warna_hex']?.toString();
//           final zoneColor = _hexToColor(warnaHex);

//           final risk = (z['tingkat_risiko'] ?? 'sedang').toString();
//           final idLaporanSumber = z['id_laporan_sumber']?.toString();
//           final tglKejadian = z['tanggal_kejadian']?.toString();
//           final wktKejadian = z['waktu_kejadian']?.toString();
//           final jam = (wktKejadian != null && wktKejadian.length >= 5)
//               ? wktKejadian.substring(0, 5)
//               : '';

//           // status color untuk badge (pending/orange, approve/red)
//           Color statusColor;
//           if (status == 'approve' ||
//               status == 'approved' ||
//               status == 'aktif') {
//             statusColor = Colors.red;
//           } else if (status == 'nonaktif') {
//             statusColor = Colors.grey;
//           } else {
//             statusColor = Colors.orange; // pending
//           }

//           return CrimeIncident(
//             id: z['id_zona'].toString(),
//             title: nama,
//             status: status,
//             time: jam.isNotEmpty ? '$tgl $jam' : tgl,
//             description: deskripsi,
//             statusColor: statusColor,
//             position: lat_lng.LatLng(lat, lon),
//             radiusMeter: radius,
//             zoneColor: zoneColor,
//             riskLevel: risk,
//             reportSourceId: idLaporanSumber,
//             tanggalKejadian: tglKejadian,
//             waktuKejadian: jam,
//           );
//         }).toList();

//         setState(() {
//           _incidents = incidents;
//         });
//         _recalcInsideZones();
//       } else {
//         debugPrint('load zona gagal: ${res.statusCode} ${res.body}');
//         _showSnack('Gagal mengambil data zona (${res.statusCode})');
//       }
//     } catch (e) {
//       debugPrint('load zona error: $e');
//       _showSnack('Terjadi kesalahan saat load data zona: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isIncidentLoading = false);
//       }
//     }
//   }

//   // ================== IZIN & LOKASI USER ==================
//   Future<bool> _handleLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showSnack('Location service belum aktif. Aktifkan GPS dulu ya.');
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showSnack(
//           'Izin lokasi ditolak. Fitur maps tidak bisa mendeteksi posisi kamu.',
//         );
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showSnack(
//         'Izin lokasi diblokir permanen. Buka Pengaturan > Aplikasi dan izinkan lokasi.',
//       );
//       return false;
//     }

//     return true;
//   }

//   Future<void> _moveToCurrentLocation() async {
//     setState(() => _isLocLoading = true);

//     final hasPermission = await _handleLocationPermission();
//     if (!hasPermission) {
//       setState(() => _isLocLoading = false);
//       return;
//     }

//     try {
//       final pos = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       final target = lat_lng.LatLng(pos.latitude, pos.longitude);

//       setState(() {
//         _currentLatLng = target;
//       });
//       _recalcInsideZones();

//       _mapController.move(target, 16);
//     } catch (e) {
//       debugPrint('getCurrentPosition error: $e');
//       _showSnack('Gagal ambil lokasi: $e');
//     } finally {
//       setState(() => _isLocLoading = false);
//     }
//   }

//   // ================== SEARCH LOKASI (OPENSTREETMAP) ==================
//   Future<void> _searchLocation() async {
//     final query = _searchController.text.trim();
//     if (query.isEmpty) return;

//     setState(() => _isSearching = true);

//     try {
//       final url = Uri.parse(
//         'https://nominatim.openstreetmap.org/search'
//         '?q=${Uri.encodeComponent(query)}'
//         '&format=json'
//         '&limit=1',
//       );

//       final res = await http.get(
//         url,
//         headers: {'User-Agent': 'sigap-mobile-app/1.0 (example@mail.com)'},
//       );

//       if (res.statusCode == 200) {
//         final List data = jsonDecode(res.body);
//         if (data.isEmpty) {
//           _showSnack('Lokasi tidak ditemukan, coba kata kunci lain.');
//         } else {
//           final first = data[0];
//           final lat = double.parse(first['lat'] as String);
//           final lon = double.parse(first['lon'] as String);

//           final target = lat_lng.LatLng(lat, lon);
//           _mapController.move(target, 15);
//         }
//       } else {
//         _showSnack('Gagal mencari lokasi (${res.statusCode}).');
//       }
//     } catch (e) {
//       _showSnack('Error saat mencari lokasi: $e');
//     } finally {
//       setState(() => _isSearching = false);
//     }
//   }

//   void _showSnack(String msg) {
//     // Kalau state-nya sudah di-dispose, jangan ngapa-ngapain
//     if (!mounted) return;

//     final messenger = ScaffoldMessenger.maybeOf(context);
//     if (messenger == null) return;

//     messenger.showSnackBar(SnackBar(content: Text(msg)));
//   }

//   // ================== REVERSE GEOCODE (LAT/LONG → ALAMAT) ==================
//   Future<void> _loadAddressForIncident(CrimeIncident incident) async {
//     final key = incident.id;

//     if (_addressCache.containsKey(key)) return;

//     setState(() => _isAddressLoading = true);

//     try {
//       final lat = incident.position.latitude;
//       final lon = incident.position.longitude;

//       final url = Uri.parse(
//         'https://nominatim.openstreetmap.org/reverse'
//         '?format=json'
//         '&lat=$lat'
//         '&lon=$lon'
//         '&zoom=18'
//         '&addressdetails=1',
//       );

//       final res = await http.get(
//         url,
//         headers: {'User-Agent': 'sigap-mobile-app/1.0 (example@mail.com)'},
//       );

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final displayName = data['display_name'] as String?;
//         if (displayName != null && mounted) {
//           setState(() {
//             _addressCache[key] = displayName;
//           });
//         }
//       } else {
//         debugPrint('Reverse geocode gagal: ${res.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Reverse geocode error: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isAddressLoading = false);
//       }
//     }
//   }

//   // ================== MARKER BUILDER ==================
//   Widget _buildIncidentMarker(CrimeIncident incident) {
//     final statusLower = incident.status.toLowerCase();

//     final bool isPending = statusLower.contains('pending');

//     if (isPending) {
//       return Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.red, width: 2),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.25),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: const Icon(Icons.question_mark, color: Colors.red, size: 30),
//       );
//     } else {
//       return const Icon(Icons.location_on, size: 40, color: Colors.red);
//     }
//   }

//   Widget _darkModeTileBuilder(
//     BuildContext context,
//     Widget tileWidget,
//     TileImage tile,
//   ) {
//     return ColorFiltered(
//       colorFilter: const ColorFilter.matrix(<double>[
//         -0.2126, -0.7152, -0.0722, 0, 255, // Red channel
//         -0.2126, -0.7152, -0.0722, 0, 255, // Green channel
//         -0.2126, -0.7152, -0.0722, 0, 255, // Blue channel
//         0, 0, 0, 1, 0, // Alpha channel
//       ]),
//       child: tileWidget,
//     );
//   }

//   // ================== BUILD ==================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF8B5A24),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: const Text(
//           'Maps Lokasi Kejahatan',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Stack(
//         children: [
//           Positioned(
//             top: 70,
//             left: 16,
//             right: 16,
//             child: _insideZones.isEmpty
//                 ? _StatusChip(
//                     text: "Kamu aman (di luar zona bahaya)",
//                     bg: Colors.green,
//                   )
//                 : _StatusChip(
//                     text:
//                         "Kamu masuk zona: ${_insideZones.map((e) => e.title).take(2).join(", ")}",
//                     bg: Colors.red,
//                   ),
//           ),

//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: const lat_lng.LatLng(-6.2, 106.816666),
//               initialZoom: 14,
//               onTap: (_, __) {
//                 setState(() => _selectedIncident = null);
//               },
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate:
//                     'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 subdomains: const ['a', 'b', 'c'],
//                 userAgentPackageName: 'com.example.mobile_app',

//               ),
//               CircleLayer(
//                 circles: _incidents
//                     .where((i) => i.radiusMeter > 0)
//                     .map(
//                       (i) => CircleMarker(
//                         point: i.position,
//                         radius: i.radiusMeter,
//                         useRadiusInMeter:
//                             true, // penting biar meter, bukan pixel
//                         color: i.zoneColor.withOpacity(0.18), // fill
//                         borderColor: i.zoneColor.withOpacity(0.9),
//                         borderStrokeWidth: 2,
//                       ),
//                     )
//                     .toList(),
//               ),
//               MarkerLayer(
//                 markers: [
//                   if (_currentLatLng != null)
//                     Marker(
//                       point: _currentLatLng!,
//                       width: 40,
//                       height: 40,
//                       child: const Icon(
//                         Icons.my_location_rounded,
//                         size: 32,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ..._incidents.map(
//                     (incident) => Marker(
//                       point: incident.position,
//                       width: 40,
//                       height: 40,
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _selectedIncident = incident;
//                           });
//                           _loadAddressForIncident(incident);
//                         },
//                         child: _buildIncidentMarker(incident),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           // SEARCH BAR
//           Positioned(
//             top: 12,
//             left: 16,
//             right: 16,
//             child: Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               child: Row(
//                 children: [
//                   const SizedBox(width: 8),
//                   const Icon(Icons.search, color: Colors.grey),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: const InputDecoration(
//                         hintText: 'Cari lokasi (contoh: Medan, Sumatera Utara)',
//                         border: InputBorder.none,
//                       ),
//                       textInputAction: TextInputAction.search,
//                       onSubmitted: (_) => _searchLocation(),
//                     ),
//                   ),
//                   if (_isSearching)
//                     const Padding(
//                       padding: EdgeInsets.only(right: 12),
//                       child: SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     )
//                   else
//                     IconButton(
//                       icon: const Icon(Icons.arrow_forward),
//                       onPressed: _searchLocation,
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           // LOADING LOKASI USER
//           if (_isLocLoading)
//             Center(
//               child: Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: const [
//                       SizedBox(
//                         height: 14,
//                         width: 14,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       SizedBox(width: 8),
//                       Text('Mencari Lokasi Anda Saat Ini...'),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // LOADING DATA ZONA
//           if (_isIncidentLoading && _incidents.isEmpty)
//             Center(
//               child: Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: const [
//                       SizedBox(
//                         height: 14,
//                         width: 14,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       SizedBox(width: 8),
//                       Text('Memuat data kejahatan...'),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // CARD DETAIL
//           if (_selectedIncident != null)
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: _IncidentDetailCard(
//                 incident: _selectedIncident!,
//                 address: _addressCache[_selectedIncident!.id],
//                 isAddressLoading: _isAddressLoading,
//                 onClose: () {
//                   setState(() => _selectedIncident = null);
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _StatusChip extends StatelessWidget {
//   final String text;
//   final Color bg;
//   const _StatusChip({required this.text, required this.bg});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: bg.withOpacity(0.92),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

// // ===== CARD DETAIL (CrimeIncident pakai model bersama) =====
// class _IncidentDetailCard extends StatelessWidget {
//   final CrimeIncident incident;
//   final String? address;
//   final bool isAddressLoading;
//   final VoidCallback onClose;

//   const _IncidentDetailCard({
//     required this.incident,
//     required this.address,
//     required this.isAddressLoading,
//     required this.onClose,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.10),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         top: false,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     incident.title.toUpperCase(),
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: onClose,
//                   icon: const Icon(Icons.close, size: 18),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 const Text(
//                   'Status : ',
//                   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//                 ),
//                 Expanded(
//                   child: Text(
//                     incident.status,
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 const Text(
//                   'Waktu  : ',
//                   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//                 ),
//                 Expanded(
//                   child: Text(
//                     incident.time,
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Lokasi : ',
//                   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//                 ),
//                 Expanded(
//                   child: isAddressLoading && address == null
//                       ? Row(
//                           children: const [
//                             SizedBox(
//                               width: 14,
//                               height: 14,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             ),
//                             SizedBox(width: 6),
//                             Text(
//                               'Mengambil alamat...',
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         )
//                       : Text(
//                           address ??
//                               'Koordinat: '
//                                   '${incident.position.latitude.toStringAsFixed(5)}, '
//                                   '${incident.position.longitude.toStringAsFixed(5)}',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Deskripsi :',
//               style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//             ),
//             const SizedBox(height: 2),
//             Text(incident.description, style: const TextStyle(fontSize: 12)),
//             const SizedBox(height: 10),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ZonaBahayaDetailPage(incident: incident),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF8B5A24),
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 child: const Text(
//                   'Detail Kejadian',
//                   style: TextStyle(color: Colors.white, fontSize: 13),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:mobile_app/widgets/blinking_widget.dart';
import 'package:mobile_app/widgets/message_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/background_zone_service.dart';
import 'crime_incident.dart';
import 'zona_bahaya_detail_page.dart';
import 'package:mobile_app/config/api_config.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'dart:typed_data';

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
  if (h.length == 6) h = 'FF$h';
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
  List<CrimeIncident> _incidents = [];
  CrimeIncident? _selectedIncident;

  bool _isLocLoading = false;
  bool _isSearching = false;
  bool _isIncidentLoading = false;
  bool _isAddressLoading = false;

  lat_lng.LatLng? _currentLatLng;
  final Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _moveToCurrentLocation();
    _loadIncidentsFromBackend();
  }

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

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] as List;

        List<Map<String, dynamic>> rawZonesForService = data.map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();

        await BackgroundZoneService.saveZones(rawZonesForService);
        await BackgroundZoneService.start();

        debugPrint(
          "Data zona berhasil disinkronkan ke Background Service: ${rawZonesForService.length} zona",
        );

        final incidents = data.map<CrimeIncident>((z) {
          final status = (z['status_zona'] ?? 'pending')
              .toString()
              .toLowerCase();
          final nama = (z['nama_zona'] ?? 'Zona tanpa nama').toString();
          final deskripsi = (z['deskripsi'] ?? '').toString();
          final tgl = z['tanggal_kejadian']?.toString() ?? '';
          final nama_pelapor = z['nama_pelapor']?.toString() ?? '';
          final lat = _toDouble(z['latitude']);
          final lon = _toDouble(z['longitude']);
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

          Color statusColor;
          if (status == 'approve' ||
              status == 'approved' ||
              status == 'aktif') {
            statusColor = Colors.red;
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
            riskLevel: risk,
            reportSourceId: idLaporanSumber,
            tanggalKejadian: tglKejadian,
            waktuKejadian: jam,
            namaPelapor: nama_pelapor,
          );
        }).toList();

        setState(() {
          _incidents = incidents;
        });
        _recalcInsideZones();
        MessagePopup.success(context, "Data Zona Berhasil Diload");
      } else if (res.statusCode != 200) {
        debugPrint('load zona gagal: ${res.statusCode} ${res.body}');
        // _showSnack('Gagal mengambil data zona (${res.statusCode})');
        MessagePopup.error(
          context,
          "Gagal Mengambil Data Zona, Silahkan Hubungi Admin",
        );
      }
    } catch (e) {
      debugPrint('load zona error: $e');
      // _showSnack('Terjadi kesalahan saat load data zona: $e');
      MessagePopup.error(
        context,
        "Terjadi Kesalahan Saat Ambil Data Zona, Silahkan Hubungi Admin",
      );
    } finally {
      if (mounted) {
        setState(() => _isIncidentLoading = false);
      }
    }
  }

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
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

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

  Widget _buildIncidentMarker(CrimeIncident incident, bool isDark) {
    final statusLower = incident.status.toLowerCase();
    final bool isPending = statusLower.contains('pending');

    if (isPending) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceGlass : Colors.white,
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

  Widget _darkModeTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.2126,
        -0.7152,
        -0.0722,
        0,
        255,
        -0.2126,
        -0.7152,
        -0.0722,
        0,
        255,
        -0.2126,
        -0.7152,
        -0.0722,
        0,
        255,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tileWidget,
    );
  }

  Widget _buildInfoCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(10),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 4,
      color: isDark ? AppColors.surfaceGlass.withOpacity(0.94) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderLight2
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Future<void> _refreshZonaData() async {
    await _loadIncidentsFromBackend();
    _recalcInsideZones();
    // _showSnack('Data zona berhasil diperbarui');
    MessagePopup.success(context, "Data Zona Berhasil Diperbaharui");
  }

  Widget _buildMapFloatingButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomOffset = _selectedIncident != null ? 510.0 : 50.0;

    Widget fab({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceGlass.withOpacity(0.96)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderLight2
                      : Colors.black.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.24 : 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                // color: isDark ? AppColors.accentLight : const Color(0xFF8B5A24),
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      right: 16,
      bottom: bottomOffset,
      child: Column(
        children: [
          fab(
            icon: Icons.my_location_rounded,
            tooltip: "Lokasi Saya",
            onTap: _moveToCurrentLocation,
          ),
          const SizedBox(height: 12),
          fab(
            icon: Icons.refresh_rounded,
            tooltip: "Refresh Zona",
            onTap: _refreshZonaData,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomOffset = 50.0;

    return Positioned(
      left: 16,
      bottom: bottomOffset,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceGlass.withOpacity(0.96)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppColors.borderLight2
                : Colors.black.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Keterangan",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _LegendItem(
              icon: Icons.my_location_rounded,
              iconColor: isDark ? AppColors.accentLight : Colors.blue,
              label: "Lokasi saya",
            ),
            const SizedBox(height: 8),
            _LegendItem(
              icon: Icons.question_mark,
              iconColor: Colors.red,
              label: "Zona pending",
              circleBorder: true,
            ),
            const SizedBox(height: 8),
            _LegendItem(
              icon: Icons.location_on,
              iconColor: Colors.red,
              label: "Zona aktif / approve",
            ),
            const SizedBox(height: 8),
            _LegendColorItem(
              color: Colors.red.withOpacity(0.28),
              borderColor: Colors.red,
              label: "Radius zona bahaya",
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            // color: isDark ? AppColors.textPrimary : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Maps Lokasi Kejahatan',
          style: TextStyle(
            // color: isDark ? AppColors.textPrimary : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          BlinkingWidget(
            child: SizedBox(
              width: 20,
              height: 20,
              // padding: EdgeInsets.all(0.30),
              child: _insideZones.isEmpty
                  ? _StatusChip(text: "G", bg: AppColors.success)
                  : _StatusChip(text: "D", bg: AppColors.danger),
            ),
          ),
          SizedBox(height: 20, width: 20),
        ],
      ),
      backgroundColor: isDark ? AppColors.bgPrimary : const Color(0xFFF4F4F4),
      body: Stack(
        children: [
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
                tileBuilder: isDark ? _darkModeTileBuilder : null,
              ),
              CircleLayer(
                circles: _incidents
                    .where((i) => i.radiusMeter > 0)
                    .map(
                      (i) => CircleMarker(
                        point: i.position,
                        radius: i.radiusMeter,
                        useRadiusInMeter: true,
                        color: i.zoneColor.withOpacity(isDark ? 0.14 : 0.18),
                        borderColor: i.zoneColor.withOpacity(0.90),
                        borderStrokeWidth: 2,
                      ),
                    )
                    .toList(),
              ),
              // MarkerLayer(
              //   markers: [
              //     if (_currentLatLng != null)
              //       Marker(
              //         point: _currentLatLng!,
              //         width: 40,
              //         height: 40,
              //         child: Icon(
              //           Icons.my_location_rounded,
              //           size: 32,
              //           color: isDark ? AppColors.accentLight : Colors.blue,
              //         ),
              //       ),
              //     ..._incidents.map(
              //       (incident) => Marker(
              //         point: incident.position,
              //         width: 90,
              //         height: 40,
              //         child: GestureDetector(
              //           onTap: () {
              //             setState(() {
              //               _selectedIncident = incident;
              //             });
              //             _loadAddressForIncident(incident);
              //           },
              //           child: Column(
              //             mainAxisSize: MainAxisSize.min,
              //             children: [
              //               // Teks Judul Besar di atas Icon
              //               Container(
              //                 padding: const EdgeInsets.symmetric(
              //                   horizontal: 8,
              //                   vertical: 4,
              //                 ),
              //                 decoration: BoxDecoration(
              //                   color: Colors.white.withOpacity(0.8),
              //                   borderRadius: BorderRadius.circular(8),
              //                   boxShadow: [
              //                     BoxShadow(
              //                       color: Colors.black26,
              //                       blurRadius: 4,
              //                       offset: Offset(0, 2),
              //                     ),
              //                   ],
              //                 ),
              //                 child: Text(
              //                   incident
              //                       .title, // Pastikan field judul sesuai dengan model data Anda
              //                   style: const TextStyle(
              //                     fontSize: 11,
              //                     fontWeight: FontWeight.bold,
              //                     color: Colors.black,
              //                   ),
              //                   textAlign: TextAlign.center,
              //                   maxLines: 2,
              //                   overflow: TextOverflow.ellipsis,
              //                 ),
              //               ),
              //               // Jarak antara teks dan icon
              //               // Icon asli Anda
              //               _buildIncidentMarker(incident, isDark),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              MarkerLayer(
                markers: [
                  if (_currentLatLng != null)
                    Marker(
                      point: _currentLatLng!,
                      width: 40,
                      height: 40,
                      // Gunakan alignment center agar icon lokasi Anda pas di tengah
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 32,
                        color: isDark ? AppColors.accentLight : Colors.blue,
                      ),
                    ),
                  ..._incidents.map(
                    (incident) => Marker(
                      point: incident.position,
                      // 1. PERBESAR lebar dan tinggi agar teks tidak overflow
                      width: 150,
                      height: 100,
                      // 2. ATUR ALIGNMENT ke topCenter.
                      // Karena teks di atas dan icon di bawah, topCenter akan mendorong
                      // bagian bawah Column (yaitu Icon) tepat ke koordinat GPS.
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIncident = incident;
                          });
                          _loadAddressForIncident(incident);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Teks Judul Besar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                incident.title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Spasi antara teks dan icon
                            const SizedBox(height: 4),
                            // Icon Marker (Sekarang posisinya akan pas di tengah radius karena alignment)
                            _buildIncidentMarker(incident, isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _buildInfoCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: isDark ? AppColors.textMuted : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi (contoh: Medan, Sumatera Utara)',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textMuted2
                              : Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        isDense: true,
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
                      icon: Icon(
                        Icons.arrow_forward,
                        color: isDark ? AppColors.textPrimary : Colors.black87,
                      ),
                      onPressed: _searchLocation,
                    ),
                ],
              ),
            ),
          ),

          if (_isLocLoading)
            Center(
              child: _buildInfoCard(
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
          _buildLegendCard(context),
          _buildMapFloatingButtons(context),

          if (_isIncidentLoading && _incidents.isEmpty)
            Center(
              child: _buildInfoCard(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: isDark ? 0.90 : 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted2 : Colors.black54;

    String timeStr = "-";
    String dateStr = "-";
    try {
      String rawDate = incident.time
          .toString(); // "2026-02-27T17:00:00.000Z 16:43"
      List<String> parts = rawDate.split(' ');

      if (parts.length > 1) {
        timeStr = parts.last; // Ambil "16:43"
      } else {
        timeStr = rawDate;
      }

      // Parse tanggalnya
      DateTime parsedDate = DateTime.parse(parts[0]).toLocal();
      dateStr = DateFormat(
        'dd-MM-yyyy',
      ).format(parsedDate); // Pastikan sudah import intl
    } catch (e) {
      // Fallback jika format data salah
      dateStr = incident.time;
      timeStr = "-";
    }

    // Fungsi helper lokal untuk membuat baris tabel agar kode tidak berulang
    TableRow buildRow(String label, Widget content) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              ":",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: content,
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlass.withOpacity(0.96) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.borderLight2
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.10),
            blurRadius: 10,
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
            // --- HEADER ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    incident.title.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, size: 18, color: textPrimary),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(), // Mengurangi padding bawaan icon
                ),
              ],
            ),

            const SizedBox(height: 8),

            // --- TABEL INFORMASI ---
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(), // Lebar menyesuaikan teks label
                1: FixedColumnWidth(16), // Lebar khusus titik dua (:)
                2: FlexColumnWidth(), // Sisanya untuk konten
              },
              children: [
                buildRow(
                  'Status',
                  Text(
                    incident.status.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ),
                buildRow(
                  'Tanggal',
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ),
                buildRow(
                  'Waktu',
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ),
                buildRow(
                  'Lokasi',
                  isAddressLoading && address == null
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mengambil alamat...',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        )
                      : Text(
                          address ??
                              'Koordinat: ${incident.position.latitude.toStringAsFixed(5)}, ${incident.position.longitude.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                ),
                buildRow(
                  'Deskripsi',
                  Text(
                    incident.description,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- FOTO KEJADIAN ---
            Text(
              "Foto Kejadian :",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _IncidentPhotoBox(incidentId: incident.id),

            const SizedBox(height: 16),

            // --- TOMBOL DETAIL ---
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
                  backgroundColor: isDark
                      ? AppColors.primaryPurple2
                      : AppColors
                            .surfaceCard, // Sesuaikan dengan warna aplikasimu
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Detail Kejadian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool circleBorder;

  const _LegendItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.circleBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: circleBorder
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.surfaceGlass : Colors.white,
                  border: Border.all(color: Colors.red, width: 1.6),
                )
              : null,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted2 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendColorItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;

  const _LegendColorItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 1.4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted2 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _IncidentPhotoBox extends StatefulWidget {
  final String incidentId;

  const _IncidentPhotoBox({required this.incidentId});

  @override
  State<_IncidentPhotoBox> createState() => _IncidentPhotoBoxState();
}

class _IncidentPhotoBoxState extends State<_IncidentPhotoBox> {
  Uint8List? _fotoBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFoto();
  }

  Future<void> _loadFoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null) {
        setState(() {
          _error = "Token tidak ditemukan";
          _loading = false;
        });
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/mobile/zona-bahaya/${widget.incidentId}/foto',
      );

      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _fotoBytes = res.bodyBytes;
          _loading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _error = "Foto tidak tersedia";
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Gagal ambil foto (${res.statusCode})";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error ambil foto: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: isDark ? AppColors.white05 : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.borderLight2
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _loading
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppColors.accentLight : Colors.brown,
                  ),
                ),
              )
            : _fotoBytes != null
            ? Image.memory(
                _fotoBytes!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            : Center(
                child: Text(
                  _error ?? "Foto tidak tersedia",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted2 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}
