// lib/pages/maps_lokasi_kejahatan/crime_incident.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as lat_lng;

class CrimeIncident {
  final String id;
  final String title;
  final String status;
  final String time;
  final String description;
  final Color statusColor;
  final lat_lng.LatLng position;
  final Image? image;
  final double radiusMeter;
  final Color zoneColor;
  final String riskLevel;
  final String? reportSourceId;
  final String? tanggalKejadian;
  final String? waktuKejadian;
  final String? namaPelapor;

  CrimeIncident({
    required this.id,
    required this.title,
    required this.status,
    required this.time,
    required this.description,
    required this.statusColor,
    required this.position,
    this.image,
    this.radiusMeter = 0,
    Color? zoneColor,
    this.riskLevel = "sedang",
    this.reportSourceId,
    this.tanggalKejadian,
    this.waktuKejadian,
    this.namaPelapor,
  }) : zoneColor = zoneColor ?? Colors.red;

  factory CrimeIncident.fromJson(Map<String, dynamic> json) {
    // 1. Ambil status untuk menentukan warna statusColor
    final String statusZona = json['status_zona']?.toString() ?? 'pending';
    final Color colorStatus = statusZona.toLowerCase() == 'pending'
        ? Colors.orange
        : Colors.green;

    // 2. Parse koordinat dengan aman
    final double lat =
        double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0;
    final double lng =
        double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0;

    // 3. Konversi Hex Color dari database (contoh: "red" atau "#FF0000")
    Color colorZone = Colors.red; // default
    if (json['warna_hex'] != null) {
      String hex = json['warna_hex'].toString();
      if (hex.startsWith('#')) {
        hex = hex.replaceAll('#', '0xFF');
        colorZone = Color(int.tryParse(hex) ?? 0xFFFF0000);
      } else if (hex.toLowerCase() == 'red') {
        colorZone = Colors.red;
      } else if (hex.toLowerCase() == 'yellow') {
        colorZone = Colors.yellow;
      } // tambahkan kondisi lain jika perlu
    }

    return CrimeIncident(
      id: json['id_zona']?.toString() ?? '',
      title: json['nama_zona']?.toString() ?? 'Tanpa Judul',
      status: statusZona,

      // Gabungkan tanggal dan waktu kejadian agar formatnya sesuai dengan
      // fungsi _extractDate dan _extractTime yang kita buat sebelumnya
      time: "${json['tanggal_kejadian']} ${json['waktu_kejadian']}",

      description: json['deskripsi']?.toString() ?? '-',
      statusColor: colorStatus,
      position: lat_lng.LatLng(lat, lng),

      radiusMeter: (json['radius_meter'] as num?)?.toDouble() ?? 100.0,
      zoneColor: colorZone,
      riskLevel: json['tingkat_risiko']?.toString() ?? 'sedang',

      // 👇 INI DIA BINTANG UTAMANYA
      namaPelapor: json['nama_pelapor']?.toString(),
      reportSourceId: json['id_laporan_sumber']?.toString(),

      tanggalKejadian: json['tanggal_kejadian']?.toString(),
      waktuKejadian: json['waktu_kejadian']?.toString(),
    );
  }
}
