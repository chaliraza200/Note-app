import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:note_app/screen/profile_screen.dart';
import 'add_edit_note_screen.dart';
import 'bookmarks_screen.dart';
import 'notification_screen.dart';
import 'package:share_plus/share_plus.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Future<void> _toggleBookmark(String noteId, bool currentValue) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('notes')
        .doc(noteId)
        .update({'isBookmarked':!currentValue});
  }
  Future<void> _logActivity(String action, String noteTitle) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('notifications')
        .add({
      'action': action, // "added", "edited", "deleted"
      'noteTitle': noteTitle.isEmpty? "Untitled" : noteTitle,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final List<Color> cardColors = [
    const Color(0xFFE8F0FE),
    const Color(0xFFFFF7ED),
    const Color(0xFFFDE2E4),
    const Color(0xFFE0E7FF),
    const Color(0xFFECFDF5),
    const Color(0xFFFFEDD5),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('notes')
          .doc(noteId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Deleted!',
            message: 'Note deleted successfully',
            contentType: ContentType.success,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'Could not delete note',
            contentType: ContentType.failure,
          ),
        ),
      );
    }
  }

  Widget _buildNotesTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "Search notes...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              filled: true,
              fillColor: Color(0xFFFAF8F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('notes')
                .orderBy('updatedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState();
              }
              final allDocs = snapshot.data!.docs;
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title']?? '').toString().toLowerCase();
                final description =
                (data['description']?? '').toString().toLowerCase();
                return title.contains(_searchQuery) ||
                    description.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text("No notes match your search"));
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String title = data['title']?? '';
                  final String description = data['description']?? '';
                  final Timestamp? updatedAt = data['updatedAt'];
                  final String formattedDate = updatedAt!= null
                      ? DateFormat('dd MMM, yyyy').format(updatedAt.toDate())
                      : '';
                  final Color cardColor = cardColors[index % cardColors.length];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditNoteScreen(
                            noteId: doc.id,
                            initialTitle: title,
                            initialDescription: description,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title.isEmpty? "Untitled" : title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF111827)),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditNoteScreen(
                                          noteId: doc.id,
                                          initialTitle: title,
                                          initialDescription: description,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    _logActivity('deleted', title);
                                    _deleteNote(doc.id);
                                  }else if (value == 'add to bookmark') {
                                    final bool isBookmarked = data['isBookmarked']?? false;
                                    _toggleBookmark(doc.id, isBookmarked);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                  PopupMenuItem(
                                    value: 'add to bookmark',
                                    child: Text((data['isBookmarked']?? false)? 'Remove Bookmark' : 'Add to Bookmarks'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildNotesTab(),
      const BookmarksScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text(
          "My Notes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 32, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Welcome!",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Organize your thoughts",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_outlined, color: Color(0xFF111827)),
              title: const Text("All Notes", style: TextStyle(color: Color(0xFF111827))),
              onTap: () {
                Navigator.pushNamed(context, "/homepage");
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF111827)),
              title: const Text("About", style: TextStyle(color: Color(0xFF111827))),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: "My Notes",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "Developed with Flutter",
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF111827)),
              title: const Text("Share App", style: TextStyle(color: Color(0xFF111827))),
              onTap: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: 'Check out My Notes app — organize your thoughts easily!\nDownload: <your_play_store_or_app_link>',
                    subject: 'My Notes App',
                  ),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "Version 1.0.0",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFF59E0B),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditNoteScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.note_add,
                  color: _selectedIndex == 0? const Color(0xFFF59E0B) : const Color(0xFF1E3A8A)),
              onPressed: () => setState(() => _selectedIndex = 0),
            ),
            IconButton(
              icon: Icon(Icons.bookmark,
                  color: _selectedIndex == 1? const Color(0xFFF59E0B) : const Color(0xFF1E3A8A)),
              onPressed: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(Icons.notification_important_rounded,
                  color: _selectedIndex == 2? const Color(0xFFF59E0B) : const Color(0xFF1E3A8A)),
              onPressed: () => setState(() => _selectedIndex = 2),
            ),
            IconButton(
              icon: Icon(Icons.person,
                  color: _selectedIndex == 3? const Color(0xFFF59E0B) : const Color(0xFF1E3A8A)),
              onPressed: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 90, color: Color(0xFF1E3A8A).withOpacity(0.3)),
          const Text(
            "No Notes Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            "Tap the + button to add your first note",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}