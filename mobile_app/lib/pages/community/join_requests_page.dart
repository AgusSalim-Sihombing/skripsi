import 'package:flutter/material.dart';
import 'package:mobile_app/services/community_service.dart';

class JoinRequestsPage extends StatefulWidget {
  final int communityId;
  const JoinRequestsPage({super.key, required this.communityId});

  @override
  State<JoinRequestsPage> createState() => _JoinRequestsPageState();
}

class _JoinRequestsPageState extends State<JoinRequestsPage> {
  bool _loading = true;
  List<dynamic> _items = [];

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await CommunityService.fetchJoinRequests(widget.communityId);
      setState(() => _items = data);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(int userId, String action) async {
    try {
      await CommunityService.respondJoinRequest(
        communityId: widget.communityId,
        userId: userId,
        action: action,
      );
      _snack(action == 'approve' ? 'Approved ✅' : 'Rejected ❌');
      await _load();
    } catch (e) {
      _snack('Gagal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No requests ✨'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    final int userId = it['user_id'] as int;
                    final username = (it['username'] ?? '').toString();
                    final nama = (it['nama'] ?? '').toString();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple.withOpacity(0.12),
                            child: const Icon(Icons.person, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(username, style: const TextStyle(fontWeight: FontWeight.w800)),
                                if (nama.isNotEmpty) Text(nama, style: TextStyle(color: Colors.grey[700])),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => _act(userId, 'reject'),
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Reject',
                          ),
                          IconButton(
                            onPressed: () => _act(userId, 'approve'),
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: 'Approve',
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
