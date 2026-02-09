import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_app/config/api_config.dart';
import 'notification_service.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value) ?? 0;
  return 0;
}

// top-level entrypoint untuk background isolate
@pragma('vm:entry-point')
Future<void> zoneServiceOnStart(ServiceInstance service) async {
  await BackgroundZoneService.onStart(service);
}

class BackgroundZoneService {
  static const String _zonesKey = 'danger_zones_json';
  static const String _cooldownPrefix = 'zone_cooldown_';
  static const String _insidePrefix = 'zone_inside_';

  static bool _configured = false;

  // ============================================================
  // Sync zona dari API (HANYA simpan ke lokal)
  // ============================================================
  static Future<int> syncDataFromApi(String token) async {
    try {
      debugPrint("🔄 [UI] Sync zona dari API...");

      final res = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        debugPrint("❌ [UI] Sync gagal: ${res.statusCode} ${res.body}");
        return 0;
      }

      final body = jsonDecode(res.body);
      final List data = (body['data'] ?? []) as List;

      final zones = data.map((e) => Map<String, dynamic>.from(e)).toList();
      await saveZones(zones);

      debugPrint("✅ [UI] Sync OK. zones=${zones.length}");
      return zones.length;
    } catch (e) {
      debugPrint("❌ [UI] Sync error: $e");
      return 0;
    }
  }

  // ============================================================
  // Configure background service (idempotent)
  // ============================================================
  static Future<void> init() async {
    if (_configured) return;

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: zoneServiceOnStart, // ✅ top-level
        autoStart: false,
        isForegroundMode: true,
        autoStartOnBoot: true,
        initialNotificationTitle: 'SIGAP aktif',
        initialNotificationContent: 'Memantau zona rawan di sekitar kamu',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: (service) {},
        onBackground: (_) async => true,
      ),
    );

    _configured = true;
  }

  static Future<void> start() async {
    final svc = FlutterBackgroundService();
    final running = await svc.isRunning();
    if (!running) {
      await svc.startService();
    }
  }

  static Future<void> stop() async {
    final svc = FlutterBackgroundService();
    svc.invoke('stopService');
    svc.invoke('stop');
  }

  static Future<void> restartHard() async {
    final svc = FlutterBackgroundService();
    final running = await svc.isRunning();

    if (running) {
      debugPrint("🟠 [UI] BG is running -> stopping...");
      await stop();

      // tunggu beneran stop (biar isolate kebuka lagi)
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        final still = await svc.isRunning();
        if (!still) break;
      }
    }

    await start();
    debugPrint("✅ [UI] BG service started (fresh)");
  }

  // ============================================================
  // Local storage
  // ============================================================
  static Future<void> saveZones(List<Map<String, dynamic>> zones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zonesKey, jsonEncode(zones));
    await prefs.reload();
  }

  static Future<List<Map<String, dynamic>>> _loadZones() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final raw = prefs.getString(_zonesKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic>? _normalizeZone(Map<String, dynamic> z) {
    final id = int.tryParse((z['id'] ?? z['id_zona']).toString()) ?? 0;
    if (id == 0) return null;

    final nama = (z['nama'] ?? z['nama_zona'] ?? 'Zona Rawan').toString();

    final lat = _toDouble(z['lat'] ?? z['latitude']);
    final lng = _toDouble(z['lng'] ?? z['longitude']);
    if (lat == 0 && lng == 0) return null;

    final radius = _toDouble(z['radiusMeter'] ?? z['radius_meter'] ?? 200);

    return {
      'id': id,
      'nama': nama,
      'lat': lat,
      'lng': lng,
      'radiusMeter': radius,
    };
  }

  static Future<bool> _isLocationServiceReady() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  static Future<bool> _cooldownOk(int zoneId,
      {required int cooldownMinutes}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final last = prefs.getInt('$_cooldownPrefix$zoneId') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMinutes = (now - last) / 60000.0;
    return diffMinutes >= cooldownMinutes;
  }

  static Future<void> _setCooldownNow(int zoneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_cooldownPrefix$zoneId',
        DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> _getInside(int zoneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool('$_insidePrefix$zoneId') ?? false;
  }

  static Future<void> _setInside(int zoneId, bool inside) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_insidePrefix$zoneId', inside);
  }

  // ============================================================
  // BG ENTRY
  // ============================================================
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    void bgLog(String msg) {
      debugPrint(msg);
      service.invoke('bg:log', {'msg': msg});
    }

    await NotificationService.init(requestPermission: false);
    bgLog("✅ [BG] onStart jalan");

    // ping/pong biar UI tau isolate hidup
    service.on('ui:ping').listen((_) {
      service.invoke('bg:pong', {'ts': DateTime.now().toIso8601String()});
    });

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'SIGAP aktif',
        content: 'Memulai pemantauan lokasi...',
      );
    }

    bool stopped = false;
    StreamSubscription<Position>? sub;
    Timer? fallbackTimer;

    Future<void> stopAll() async {
      if (stopped) return;
      stopped = true;
      await sub?.cancel();
      fallbackTimer?.cancel();
      service.stopSelf();
      bgLog("🛑 [BG] stopped");
    }

    service.on('stopService').listen((_) => stopAll());
    service.on('stop').listen((_) => stopAll());

    Future<void> handlePosition(Position pos) async {
      if (stopped) return;

      // kirim ke UI biar keliatan update real-time
      service.invoke('bg:loc', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'acc': pos.accuracy,
        'ts': DateTime.now().toIso8601String(),
      });

      try {
        final zonesRaw = await _loadZones();
        if (zonesRaw.isEmpty) {
          bgLog("⚠️ [BG] zones kosong");
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'SIGAP aktif',
              content: 'Tidak ada zona tersimpan',
            );
          }
          return;
        }

        double nearest = double.infinity;
        String nearestName = "-";

        for (final raw in zonesRaw) {
          final z = _normalizeZone(raw);
          if (z == null) continue;

          final id = z['id'] as int;
          final nama = z['nama'] as String;
          final lat = z['lat'] as double;
          final lng = z['lng'] as double;
          final radius = z['radiusMeter'] as double;

          final distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            lat,
            lng,
          );

          if (distance < nearest) {
            nearest = distance;
            nearestName = nama;
          }

          final inside = await _getInside(id);

          // ENTER ZONE
          if (distance <= radius) {
            if (!inside) {
              final canNotify = await _cooldownOk(id, cooldownMinutes: 10);
              if (canNotify) {
                await NotificationService.showZoneWarning(
                  id: 10000 + id,
                  title: '⚠️ Waspada! Zona Bahaya',
                  body: 'Kamu masuk radius ${radius.toInt()}m dari: $nama',
                );
                await _setCooldownNow(id);
                bgLog("🚨 [BG] ENTER -> NOTIF: $nama");
              } else {
                bgLog("⏳ [BG] ENTER tapi cooldown: $nama");
              }
              await _setInside(id, true);
            }
          } else {
            // EXIT ZONE
            if (inside) {
              await _setInside(id, false);
              bgLog("✅ [BG] EXIT: $nama");
            }
          }
        }

        if (service is AndroidServiceInstance) {
          final nearestText = nearest.isFinite
              ? '$nearestName (${nearest.toStringAsFixed(0)}m)'
              : 'Tidak ada zona valid';

          service.setForegroundNotificationInfo(
            title: 'SIGAP aktif',
            content: 'Terdekat: $nearestText',
          );
        }
      } catch (e, st) {
        bgLog("❌ [BG] error handlePosition: $e");
        bgLog("$st");
      }
    }

    // ✅ jangan mati kalau GPS belum ready; keep hidup & coba lagi via timer
    Future<void> ensureStreamStarted() async {
      if (stopped) return;
      if (sub != null) return;

      final ready = await _isLocationServiceReady();
      if (!ready) {
        bgLog("⚠️ [BG] lokasi belum siap (cek GPS/izin)");
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'SIGAP aktif',
            content: 'Lokasi belum siap (cek GPS/izin lokasi)',
          );
        }
        return;
      }

      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) => handlePosition(pos),
        onError: (e) => bgLog("❌ [BG] stream error: $e"),
      );

      bgLog("✅ [BG] position stream started");

      // trigger sekali biar kalau user sudah di dalam zona, langsung ke-detect
      try {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await handlePosition(p);
      } catch (e) {
        bgLog("❌ [BG] initial getCurrentPosition error: $e");
      }
    }

    // coba start sekarang
    await ensureStreamStarted();

    // fallback polling (kalau stream pelit / GPS baru dinyalain)
    fallbackTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (stopped) return;

      // kalau stream belum jalan, coba start lagi
      if (sub == null) {
        await ensureStreamStarted();
        return;
      }

      // tetap polling biar UI keliatan update
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await handlePosition(pos);
      } catch (e) {
        bgLog("❌ [BG] fallback getCurrentPosition error: $e");
      }
    });
  }
}
