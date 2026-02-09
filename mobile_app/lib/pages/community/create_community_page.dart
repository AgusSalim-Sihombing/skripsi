import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/services/community_service.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _nameC = TextEditingController();
  final _searchC = TextEditingController();

  File? _iconFile;
  bool _saving = false;

  List<dynamic> _searchResults = [];
  final List<String> _selectedUsernames = [];

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    _nameC.dispose();
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (x == null) return;
    setState(() => _iconFile = File(x.path));
  }

  Future<void> _searchUser(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final res = await CommunityService.searchUsers(query);
      setState(() => _searchResults = res);
    } catch (e) {
      _snack('Error search: $e');
    }
  }

  Future<void> _create() async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      _snack('Nama grup wajib');
      return;
    }

    setState(() => _saving = true);
    try {
      await CommunityService.createCommunity(
        name: name,
        memberUsernames: _selectedUsernames,
        iconFile: _iconFile,
      );

      _snack('Komunitas dibuat ✅');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Komunitas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon + name
            Row(
              children: [
                InkWell(
                  onTap: _saving ? null : _pickIcon,
                  borderRadius: BorderRadius.circular(18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.deepPurple.withOpacity(0.12),
                      child: _iconFile != null
                          ? Image.file(_iconFile!, fit: BoxFit.cover)
                          : const Icon(
                              Icons.add_a_photo,
                              color: Colors.deepPurple,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameC,
                    decoration: InputDecoration(
                      labelText: 'Nama Grup',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Tambah Member (by username)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _searchC,
              onChanged: _searchUser,
              decoration: InputDecoration(
                hintText: 'Search username...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_selectedUsernames.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedUsernames
                    .map(
                      (u) => Chip(
                        label: Text(u),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: _saving
                            ? null
                            : () =>
                                  setState(() => _selectedUsernames.remove(u)),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 10),

            if (_searchResults.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (_, i) {
                    final it = _searchResults[i];
                    final username = (it['username'] ?? '').toString();
                    final nama = (it['nama'] ?? '').toString();

                    final already = _selectedUsernames.contains(username);

                    return ListTile(
                      title: Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: nama.isNotEmpty ? Text(nama) : null,
                      trailing: already
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.add_circle_outline),
                      onTap: _saving
                          ? null
                          : () {
                              if (!already) {
                                setState(
                                  () => _selectedUsernames.add(username),
                                );
                              }
                            },
                    );
                  },
                ),
              ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: _saving ? null : _create,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
