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

  }) : zoneColor = zoneColor ?? Colors.red;
}
