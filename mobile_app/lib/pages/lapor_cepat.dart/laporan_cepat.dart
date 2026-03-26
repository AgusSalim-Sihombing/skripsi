import 'dart:convert';
import 'dart:io';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/message_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/api_config.dart';

// ✅ TAMBAH INI
import 'package:geolocator/geolocator.dart';

class LaporCepatPage extends StatefulWidget {
  // const LaporCepatPage({Key? key}) : super(key: key);
  const LaporCepatPage({super.key});

  @override
  State<LaporCepatPage> createState() => _LaporCepatPageState();
}

class _LaporCepatPageState extends State<LaporCepatPage> {
  final _formKey = GlobalKey<FormState>();

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final MapController _mapController = MapController();
  lat_lng.LatLng? _selectedLatLng;

  // ✅ TAMBAH: lokasi user
  lat_lng.LatLng? _userLatLng;

  // ✅ TAMBAH: search bar
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  XFile? _pickedImage;
  bool _isAnonim = false;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initUserLocation(); // ✅ map langsung ke lokasi user
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();

    // ✅ TAMBAH
    _searchController.dispose();

    super.dispose();
  }

  // ==================== INIT LOKASI USER ====================
  Future<void> _initUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final me = lat_lng.LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() {
        _userLatLng = me;

        // biar default lokasi kejadian otomatis di lokasi user (kalau belum dipilih)
        _selectedLatLng ??= me;
      });

      // geser map ke lokasi user
      _mapController.move(me, 16);
    } catch (e) {
      debugPrint("init lokasi error: $e");
    }
  }

  // ==================== SEARCH LOKASI (NOMINATIM) ====================
  Future<void> _searchLocation() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    setState(() => _searching = true);

    try {
      final uri = Uri.https("nominatim.openstreetmap.org", "/search", {
        "q": q,
        "format": "json",
        "limit": "1",
      });

      final resp = await http.get(
        uri,
        headers: {
          // penting buat Nominatim
          "User-Agent": "sigap_app/1.0 (mobile)",
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        if (list.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lokasi tidak ditemukan 😭")),
          );
          return;
        }

        final first = list.first as Map<String, dynamic>;
        final lat = double.parse(first["lat"].toString());
        final lon = double.parse(first["lon"].toString());

        final point = lat_lng.LatLng(lat, lon);

        setState(() {
          // auto set lokasi kejadian = hasil search
          _selectedLatLng = point;
        });

        _mapController.move(point, 16);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search gagal (${resp.statusCode})")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error search: $e")));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goToMyLocation() {
    if (_userLatLng == null) return;
    _mapController.move(_userLatLng!, 16);
    setState(() {
      _selectedLatLng = _userLatLng;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDate: _selectedDate ?? now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // ==================== PICKER FOTO ====================
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (img != null) {
      setState(() {
        _pickedImage = img;
      });
    }
  }

  // ==================== SUBMIT ====================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih lokasi di peta terlebih dahulu'),
        ),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal dan waktu kejadian wajib diisi')),
      );
      return;
    }

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil / pilih foto kejadian')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan, silakan login ulang'),
        ),
      );
      return;
    }

    final tanggal = _selectedDate!;
    final tanggalStr =
        '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';

    final waktu = _selectedTime!;
    final waktuStr =
        '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';

    setState(() {
      _submitting = true;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/mobile/laporan-cepat');

      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['judul_laporan'] = _judulController.text.trim();
      request.fields['deskripsi'] = _deskripsiController.text.trim();
      request.fields['latitude'] = _selectedLatLng!.latitude.toString();
      request.fields['longitude'] = _selectedLatLng!.longitude.toString();
      request.fields['tanggal_kejadian'] = tanggalStr;
      request.fields['waktu_kejadian'] = waktuStr;
      request.fields['is_anonim'] = _isAnonim ? '1' : '0';

      final bytes = await _pickedImage!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: 'laporan_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true || data['message'] != null) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Laporan berhasil dikirim')),
          // );
          MessagePopup.success(context, "Laporan Berhasil Dikirim");

          setState(() {
            _judulController.clear();
            _deskripsiController.clear();
            _selectedDate = null;
            _selectedTime = null;

            // biar setelah reset, balik ke lokasi user (kalau ada)
            _selectedLatLng = _userLatLng;

            _pickedImage = null;
            _isAnonim = false;
          });

          if (_userLatLng != null) {
            _mapController.move(_userLatLng!, 16);
          }
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(data['message'] ?? 'Gagal mengirim laporan'),
          //   ),
          // );
          MessagePopup.error(context, "Gagal Mengirim Laporan");
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengirim laporan (401): ${jsonDecode(response.body)['message'] ?? 'Unauthorized'}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim laporan (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      debugPrint('submit error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Cepat Kejahatan'),
        // backgroundColor: const Color(0xFF8B5A24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // JUDUL
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul Kejahatan',
                  hintText: 'Contoh: Tawuran pelajar di jembatan...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // DESKRIPSI
              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Ceritakan singkat kronologi kejadian...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // MAP PICKER
              const Text(
                'Pilih Lokasi Kejadian di Peta',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 330,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _selectedLatLng ??
                              _userLatLng ??
                              lat_lng.LatLng(-6.2, 106.816666),
                          initialZoom: 15,
                          onTap: (_, latlng) {
                            setState(() {
                              _selectedLatLng = latlng;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.example.sigap_app',
                          ),

                          // ✅ Marker lokasi user
                          if (_userLatLng != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _userLatLng!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),

                          // Marker lokasi yang dipilih
                          if (_selectedLatLng != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLatLng!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // ✅ tombol kecil My Location
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: "btn_my_location",
                          backgroundColor: Colors.white,
                          onPressed: _goToMyLocation,
                          child: Icon(
                            Icons.my_location,
                            color: _userLatLng == null
                                ? Colors.grey
                                : Colors.blue,
                          ),
                        ),
                      ),

                      // ✅ SEARCH BAR (di atas map)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (_) => _searchLocation(),
                                    decoration: const InputDecoration(
                                      hintText:
                                          "Cari lokasi (contoh: USU, Medan)",
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _searching
                                      ? null
                                      : _searchLocation,
                                  icon: _searching
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                _selectedLatLng == null
                    ? 'Belum ada lokasi dipilih.'
                    : 'Lokasi: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, '
                          '${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),

              // ... sisanya BIARIN (tanggal/waktu, foto, anonim, submit) ...
              // (aku gak ubah apa-apa di bawah ini)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Kejadian',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Pilih tanggal'
                              : '${_selectedDate!.day.toString().padLeft(2, '0')}-'
                                    '${_selectedDate!.month.toString().padLeft(2, '0')}-'
                                    '${_selectedDate!.year}',
                          // style: TextStyle(
                          //   color: _selectedDate == null
                          //       ? Colors.grey
                          //       : Colors.black87,
                          // ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Waktu Kejadian',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Pilih waktu'
                              : '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
                                    '${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          // style: TextStyle(
                          //   color: _selectedTime == null
                          //       ? Colors.grey
                          //       : Colors.black87,
                          // ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Foto Kejadian',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'Ambil Foto',
                      // style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.primaryPurple2
                          : AppColors.accentSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_pickedImage != null)
                    Expanded(
                      child: Text(
                        _pickedImage!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (_pickedImage != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_pickedImage!.path),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kirim sebagai anonim'),
                subtitle: const Text(
                  'Jika aktif, nama & data identitasmu tidak akan ditampilkan ke admin.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _isAnonim,
                onChanged: (val) {
                  setState(() {
                    _isAnonim = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.accentPurple
                        : AppColors.glowPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _submitting ? 'Mengirim...' : 'Kirim Laporan',
                    // style: const TextStyle(
                    //   color: Colors.white,
                    //   fontWeight: FontWeight.w600,
                    // ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
