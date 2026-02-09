import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'crime_incident.dart';
import 'package:mobile_app/config/api_config.dart';
// sesuaikan baseUrl sama yang lain (lapor cepat, login, dll)
// const String apiBaseUrl = 'http://10.121.204.17:3000/api';

class ZonaBahayaDetailPage extends StatefulWidget {
  final CrimeIncident incident;

  const ZonaBahayaDetailPage({Key? key, required this.incident})
    : super(key: key);

  @override
  State<ZonaBahayaDetailPage> createState() => _ZonaBahayaDetailPageState();
}

class _ZonaBahayaDetailPageState extends State<ZonaBahayaDetailPage> {
  bool _loadingSummary = false;
  bool _submittingVote = false;

  int _totalSetuju = 0;
  int _totalTidakSetuju = 0;
  int _totalVote = 0;
  int _persenSetuju = 0;
  int _persenTidakSetuju = 0;
  String? _myVote; // "setuju" / "tidak_setuju" / null
  Uint8List? _fotoBytes;
  bool _loadingFoto = false;
  String? _fotoError;

  @override
  void initState() {
    super.initState();
    _loadVoteSummary();
    _loadZonaFoto();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  int? get _idZonaParsed {
    final id = int.tryParse(widget.incident.id);
    return id;
  }

  // helper biar aman kalau backend kirim string / int / double
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ============ GET SUMMARY VOTE ============
  Future<void> _loadVoteSummary() async {
    final idZona = _idZonaParsed;
    if (idZona == null) {
      _showSnack("ID zona tidak valid (bukan angka)");
      return;
    }

    setState(() => _loadingSummary = true);

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnack("Token tidak ditemukan, silakan login ulang");
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/mobile/zona-bahaya/$idZona/votes-summary',
      );

      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('votes-summary body: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        // backend kirim "status": "success"
        final statusFlag = decoded['status'];
        final successFlag = decoded['success'];

        if (statusFlag == 'success' || successFlag == true) {
          final d = decoded['data'] ?? {};

          final totalSetuju = _toInt(d['total_setuju']);
          final totalTidak = _toInt(
            d['total_tidak'] ?? d['total_tidak_setuju'],
          );
          final totalVoteRaw = _toInt(d['total_vote']);

          final persenSetuju = _toInt(d['persen_setuju']);
          final persenTidak = _toInt(d['persen_tidak_setuju']);

          final myVoteRaw = d['my_vote'];
          final myVote = myVoteRaw == null ? null : myVoteRaw.toString();

          setState(() {
            _totalSetuju = totalSetuju;
            _totalTidakSetuju = totalTidak;
            _totalVote = totalVoteRaw != 0
                ? totalVoteRaw
                : totalSetuju + totalTidak;

            // kalau backend sudah kirim persen, pakai itu;
            // kalau nggak, hitung manual
            if (_totalVote > 0) {
              _persenSetuju = persenSetuju != 0
                  ? persenSetuju
                  : ((_totalSetuju * 100) / _totalVote).round();
              _persenTidakSetuju = persenTidak != 0
                  ? persenTidak
                  : ((_totalTidakSetuju * 100) / _totalVote).round();
            } else {
              _persenSetuju = 0;
              _persenTidakSetuju = 0;
            }

            _myVote = myVote;
          });

          debugPrint(
            'Vote summary => setuju=$_totalSetuju tidak=$_totalTidakSetuju total=$_totalVote '
            'pSetuju=$_persenSetuju pTidak=$_persenTidakSetuju myVote=$_myVote',
          );
        } else {
          _showSnack(decoded['message'] ?? 'Gagal ambil data voting');
        }
      } else {
        _showSnack('Gagal ambil data voting (${res.statusCode})');
      }
    } catch (e) {
      _showSnack('Error mengambil voting: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingSummary = false);
      }
    }
  }

  Future<void> _loadZonaFoto() async {
    final idZona = _idZonaParsed;
    if (idZona == null) return;

    setState(() {
      _loadingFoto = true;
      _fotoError = null;
      _fotoBytes = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _fotoError = "Token tidak ditemukan";
          _loadingFoto = false;
        });
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/mobile/zona-bahaya/$idZona/foto',
      );

      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _fotoBytes = res.bodyBytes;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _fotoError = "Zona ini tidak punya foto";
        });
      } else {
        setState(() {
          _fotoError = "Gagal ambil foto (${res.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _fotoError = "Error ambil foto: $e";
      });
    } finally {
      if (mounted) setState(() => _loadingFoto = false);
    }
  }

  // ============ KIRIM VOTE ============
  Future<void> _sendVote(String vote) async {
    if (_submittingVote) return;

    final idZona = _idZonaParsed;
    if (idZona == null) {
      _showSnack("ID zona tidak valid (bukan angka)");
      return;
    }

    setState(() => _submittingVote = true);

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnack("Token tidak ditemukan, silakan login ulang");
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/mobile/zona-bahaya/$idZona/vote',
      );

      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'vote': vote}),
      );

      final body = jsonDecode(res.body);
      debugPrint('vote response: ${res.statusCode} => $body');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final statusFlag = body['status'];
        final successFlag = body['success'];

        if (statusFlag == 'success' || successFlag == true) {
          _showSnack(body['message'] ?? "Vote berhasil disimpan");
          // refresh summary + my_vote dari server
          await _loadVoteSummary();
        } else {
          _showSnack(body['message'] ?? 'Gagal menyimpan vote');
        }
      } else {
        _showSnack(
          body['message'] ?? 'Gagal menyimpan vote (${res.statusCode})',
        );
      }
    } catch (e) {
      _showSnack('Error saat mengirim vote: $e');
    } finally {
      if (mounted) {
        setState(() => _submittingVote = false);
      }
    }
  }

  bool get _isVoteSetuju => (_myVote ?? '').toLowerCase() == 'setuju';

  bool get _isVoteTidak {
    final v = (_myVote ?? '').toLowerCase();
    return v == 'tidak' || v == 'tidak_setuju';
  }

  bool get _hasVoted => _myVote != null;

  // ============ UI BANTUAN ============
  Widget _buildVoteBar() {
    if (_totalVote == 0) {
      return const Text(
        "Belum ada voting, jadilah yang pertama memberi penilaian.",
        style: TextStyle(fontSize: 13),
      );
    }

    final int pSetuju = _persenSetuju != 0
        ? _persenSetuju
        : ((_totalSetuju * 100) / _totalVote).round();
    final int pTidak = _persenTidakSetuju != 0
        ? _persenTidakSetuju
        : ((_totalTidakSetuju * 100) / _totalVote).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: pSetuju,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Expanded(
                  flex: pTidak,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Setuju: $_totalSetuju orang ($pSetuju%)",
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          "Tidak setuju: $_totalTidakSetuju orang ($pTidak%)",
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _myVoteText() {
    final v = (_myVote ?? '').toLowerCase();
    if (v == "setuju") return "Kamu memilih: SETUJU";
    if (v == "tidak" || v == "tidak_setuju") {
      return "Kamu memilih: TIDAK SETUJU";
    }
    return "Kamu belum memberikan vote";
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final isPending = incident.status.toLowerCase().contains('pending');

    return Scaffold(
      appBar: AppBar(
        title: Text(incident.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF8B5A24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== INFO ZONA / KEJADIAN ====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // === CHIP STATUS ===
                        Expanded(
                          child: Container(
                            // margin = const EdgeInsets.only(right: 4),
                            child: Chip(
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Status: ${incident.status.toUpperCase()}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              backgroundColor: isPending
                                  ? Colors.orange
                                  : Colors.green,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // === CHIP WAKTU ===
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: Chip(
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Waktu: ${incident.time}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              backgroundColor: Colors.blueGrey,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Koordinat: "
                      "${incident.position.latitude.toStringAsFixed(5)}, "
                      "${incident.position.longitude.toStringAsFixed(5)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Radius: ${incident.radiusMeter.toStringAsFixed(0)} meter",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Tingkat Risiko: ${incident.riskLevel.toUpperCase()}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (incident.reportSourceId != null)
                      Text(
                        "Sumber Laporan: #${incident.reportSourceId}",
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Foto Kejadian",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _loadingFoto
                    ? Row(
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text("Memuat foto..."),
                        ],
                      )
                    : _fotoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.memory(
                            _fotoBytes!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _fotoError ?? "Foto tidak tersedia",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ==== BAGIAN VOTING ====
            Row(
              children: [
                const Text(
                  "Voting Zona Ini",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                if (_loadingSummary)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            _buildVoteBar(),
            const SizedBox(height: 8),

            Text(
              _myVoteText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _myVote == null ? Colors.grey.shade600 : Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),

            if (!isPending)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Zona ini sudah tidak dalam tahap voting. "
                  "Voting hanya bisa dilakukan saat status masih PENDING.",
                  style: TextStyle(fontSize: 12),
                ),
              ),

            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_submittingVote || _hasVoted)
                          ? null
                          : () => _sendVote("setuju"),
                      icon: const Icon(Icons.thumb_up),
                      label: Text(_isVoteSetuju ? "Sudah Setuju" : "Setuju"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVoteSetuju
                            ? Colors.green
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_submittingVote || _hasVoted)
                          ? null
                          : () => _sendVote("tidak_setuju"),
                      icon: const Icon(Icons.thumb_down),
                      label: Text(
                        _isVoteTidak ? "Sudah Tidak Setuju" : "Tidak Setuju",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVoteTidak
                            ? Colors.red
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
