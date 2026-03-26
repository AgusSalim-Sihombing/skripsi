import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/community_service.dart';
import 'package:mobile_app/pages/community/create_community_page.dart';
import 'package:mobile_app/pages/community/community_chat_page.dart';

class CommunityLobbyPage extends StatefulWidget {
  const CommunityLobbyPage({super.key});

  @override
  State<CommunityLobbyPage> createState() => _CommunityLobbyPageState();
}

class _CommunityLobbyPageState extends State<CommunityLobbyPage> {
  final _searchC = TextEditingController();

  bool _eligible = false;
  bool _loading = true;
  bool _refreshing = false;

  List<dynamic> _items = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initEligibility();
  }

  Future<void> _initEligibility() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    final verif = prefs.getString('status_verifikasi') ?? '';

    setState(() {
      _eligible = (role == 'masyarakat' && verif == 'verified');
    });

    if (_eligible) {
      await _fetch();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await CommunityService.fetchCommunities(
        search: _searchC.text.trim(),
      );
      setState(() => _items = data);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final data = await CommunityService.fetchCommunities(
        search: _searchC.text.trim(),
      );
      setState(() => _items = data);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.dispose();
    super.dispose();
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Member';
      case 'pending_join':
        return 'Pending';
      case 'invited':
        return 'Invited';
      case 'rejected':
        return 'Rejected';
      case 'banned':
        return 'Banned';
      default:
        return 'Join';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return Colors.green;
      case 'pending_join':
        return Colors.orange;
      case 'invited':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'banned':
        return Colors.black54;
      default:
        return Colors.deepPurple;
    }
  }

  // Future<void> _handleTap(dynamic item) async {
  //   final int id = item['id'] as int;
  //   final String name = (item['name'] ?? '').toString();
  //   final String myStatus = (item['my_status'] ?? 'none').toString();

  //   if (myStatus == 'approved') {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) =>
  //             CommunityChatPage(communityId: id, communityName: name),
  //       ),
  //     );
  //     return;
  //   }

  //   if (myStatus == 'pending_join') {
  //     _snack('Masih nunggu persetujuan owner yaa ✋');
  //     return;
  //   }

  //   if (myStatus == 'banned') {
  //     _snack('Kamu dibanned dari komunitas ini.');
  //     return;
  //   }

  //   if (myStatus == 'invited') {
  //     final ok = await showDialog<bool>(
  //       context: context,
  //       builder: (_) => AlertDialog(
  //         title: Text('Undangan ke "$name"'),
  //         content: const Text('Mau terima undangannya?'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text('Tolak'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             child: const Text('Terima'),
  //           ),
  //         ],
  //       ),
  //     );

  //     if (ok == true) {
  //       try {
  //         await CommunityService.acceptInvite(id);
  //         _snack('Invite diterima ✅');
  //         await _refresh();
  //       } catch (e) {
  //         _snack('Error: $e');
  //       }
  //     } else if (ok == false) {
  //       try {
  //         await CommunityService.declineInvite(id);
  //         _snack('Invite ditolak ❌');
  //         await _refresh();
  //       } catch (e) {
  //         _snack('Error: $e');
  //       }
  //     }
  //     return;
  //   }

  //   // default: none / rejected -> join request
  //   final join = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: Text('Join "$name"?'),
  //       content: const Text('Kamu bakal kirim request ke owner buat join.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('Join'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (join == true) {
  //     try {
  //       await CommunityService.requestJoin(id);
  //       _snack('Request join terkirim ✅');
  //       await _refresh();
  //     } catch (e) {
  //       _snack('Error: $e');
  //     }
  //   }
  // }

  Future<void> _handleTap(dynamic item) async {
    final int id = item['id'] as int;
    final String name = (item['name'] ?? '').toString();
    final String myStatus = (item['my_status'] ?? 'none').toString();
    final String communityStatus = (item['status'] ?? 'active').toString();
    final String takedownReason = (item['takedown_reason'] ?? '').toString();

    // kalau komunitas sedang takedown
    if (communityStatus == 'takedown') {
      if (myStatus == 'approved') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityChatPage(
              communityId: id,
              communityName: name,
              communityStatus: communityStatus,
              takedownReason: takedownReason,
            ),
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Komunitas Dinonaktifkan'),
          content: Text(
            takedownReason.isNotEmpty
                ? 'Komunitas ini sedang ditakedown admin.\n\nAlasan:\n$takedownReason'
                : 'Komunitas ini sedang ditakedown admin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    if (myStatus == 'approved') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityChatPage(
            communityId: id,
            communityName: name,
            communityStatus: communityStatus,
            takedownReason: takedownReason,
          ),
        ),
      );
      return;
    }

    if (myStatus == 'pending_join') {
      _snack('Masih nunggu persetujuan owner yaa ✋');
      return;
    }

    if (myStatus == 'banned') {
      _snack('Kamu dibanned dari komunitas ini.');
      return;
    }

    if (myStatus == 'invited') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Undangan ke "$name"'),
          content: const Text('Mau terima undangannya?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tolak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Terima'),
            ),
          ],
        ),
      );

      if (ok == true) {
        try {
          await CommunityService.acceptInvite(id);
          _snack('Invite diterima ✅');
          await _refresh();
        } catch (e) {
          _snack('Error: $e');
        }
      } else if (ok == false) {
        try {
          await CommunityService.declineInvite(id);
          _snack('Invite ditolak ❌');
          await _refresh();
        } catch (e) {
          _snack('Error: $e');
        }
      }
      return;
    }

    final join = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Join "$name"?'),
        content: const Text('Kamu bakal kirim request ke owner buat join.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (join == true) {
      try {
        await CommunityService.requestJoin(id);
        _snack('Request join terkirim ✅');
        await _refresh();
      } catch (e) {
        _snack('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible) {
      return Scaffold(
        appBar: AppBar(title: const Text('Komunitas')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Fitur Komunitas cuma buat akun Masyarakat yang sudah Verified.\n\n'
              'Kalau akun kamu masih Pending, tunggu verifikasi admin dulu ya 🙏',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunitas'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateCommunityPage()),
          );

          if (created == true) {
            await _refresh();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchC,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  _fetch();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari komunitas...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: _items.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'Belum ada komunitas\nBikin yang pertama yuk!',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final it = _items[i];
                              final id = it['id'];
                              final name = (it['name'] ?? '').toString();
                              final owner = (it['owner_username'] ?? '')
                                  .toString();
                              final status = (it['my_status'] ?? 'none')
                                  .toString();
                              final memberCount = (it['member_count'] ?? 0)
                                  .toString();
                              final lastMsg = (it['last_message'] ?? '')
                                  .toString();

                              final iconUrl = '${it['icon_url'] ?? ''}';

                              final communityStatus = (it['status'] ?? 'active')
                                  .toString();
                              final takedownReason =
                                  (it['takedown_reason'] ?? '').toString();

                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _handleTap(it),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      _CommunityIcon(iconUrl: iconUrl),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Owner: $owner • $memberCount member',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (lastMsg.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                lastMsg,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                            if (communityStatus ==
                                                'takedown') ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.10,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  takedownReason.isNotEmpty
                                                      ? 'Dinonaktifkan admin: $takedownReason'
                                                      : 'Dinonaktifkan admin',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            status,
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
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

class _CommunityIcon extends StatefulWidget {
  final String iconUrl;
  const _CommunityIcon({required this.iconUrl});

  @override
  State<_CommunityIcon> createState() => _CommunityIconState();
}

class _CommunityIconState extends State<_CommunityIcon> {
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    _loadHeaders();
  }

  Future<void> _loadHeaders() async {
    final h = await CommunityService.authHeaderOnly();
    if (mounted) setState(() => _headers = h);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.iconUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        color: Colors.deepPurple.withOpacity(0.12),
        child: (url.isNotEmpty && _headers != null)
            ? Image.network(
                url,
                headers: _headers!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.group, color: Colors.deepPurple),
              )
            : const Icon(Icons.group, color: Colors.deepPurple),
      ),
    );
  }
}
