import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/community_service.dart';
import 'package:mobile_app/pages/community/join_requests_page.dart';
import 'package:mobile_app/services/socket_service.dart';

class CommunityChatPage extends StatefulWidget {
  final int communityId;
  final String communityName;

  const CommunityChatPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final _msgC = TextEditingController();
  final _scroll = ScrollController();

  late final SocketService _socket;

  List<Map<String, dynamic>> _messages = [];

  bool _loading = true;
  bool _sending = false;
  bool _isOwner = false;

  int? _myUserId;

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  @override
  void initState() {
    super.initState();
    _socket =
        SocketService(); // ✅ sekarang ambil instance yang sama (singleton)

    _init();
    _setupRealtime();
  }

  void _setupRealtime() {
    _socket.off("community:message");
    _socket.off("socket:ready");

    void doJoin() {
      _socket.joinCommunity(widget.communityId);
      print("🏠 join room community:${widget.communityId} (client)");
    }

    if (_socket.isConnected) {
      doJoin();
    } else {
      // kalau belum connect/ready, tunggu server ready
      _socket.on("socket:ready", (_) => doJoin());
    }

    _socket.on("community:message", (data) {
      final msg = Map<String, dynamic>.from(data);

      if (msg["communityId"] != widget.communityId) return;

      final incomingId = msg["id"];
      final exists = _messages.any((m) => m["id"] == incomingId);
      if (exists) return;

      if (!mounted) return;
      setState(() => _messages.add(msg));
      _jumpToBottom();
    });
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getInt('user_id');

    await _loadMessages();
    await _checkOwner();
  }

  Future<void> _checkOwner() async {
    try {
      // kalau sukses, berarti owner (endpoint owner-only)
      await CommunityService.fetchJoinRequests(widget.communityId);
      if (mounted) setState(() => _isOwner = true);
    } catch (e) {
      if ('$e'.contains('FORBIDDEN_OWNER')) {
        if (mounted) setState(() => _isOwner = false);
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final data = await CommunityService.fetchMessages(
        communityId: widget.communityId,
        limit: 80,
      );

      final mapped = data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;
      setState(() => _messages = mapped);
      _jumpToBottom();

      _jumpToBottom();
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      await CommunityService.sendMessage(
        communityId: widget.communityId,
        message: text,
      );

      _msgC.clear();

      // ✅ jangan refresh full.
      // realtime socket akan nambahin message sendiri.
      // kalau socket lagi mati, fallback refresh sekali:
      if (!_socket.isConnected) {
        await _loadMessages();
      }
    } catch (e) {
      _snack('Gagal kirim: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _msgC.dispose();
    _scroll.dispose();

    _socket.leaveCommunity(widget.communityId);
    _socket.off("community:message");
    _socket.off("socket:ready");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.how_to_reg),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JoinRequestsPage(communityId: widget.communityId),
                  ),
                );
              },
              tooltip: 'Join Requests',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final senderId = m['sender_user_id'];
                      final username = (m['username'] ?? '').toString();
                      final message = (m['message'] ?? '').toString();
                      final isDeleted = (m['is_deleted'] ?? 0) == 1;

                      final mine = (_myUserId != null && senderId == _myUserId);

                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: mine ? Colors.deepPurple : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                mine ? 'Kamu' : username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: mine ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDeleted ? '[pesan dihapus]' : message,
                                style: TextStyle(
                                  color: mine ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgC,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
