import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // ── Returns icon + label text based on the logged action ──
  Map<String, dynamic> _actionInfo(String action) {
    switch (action) {
      case 'added':
        return {'icon': Icons.note_add, 'label': 'added', 'color': Color(0xFF1E3A8A)};
      case 'edited':
        return {'icon': Icons.edit, 'label': 'edited', 'color': Color(0xFFF59E0B)};
      case 'deleted':
        return {'icon': Icons.delete, 'label': 'deleted', 'color': Colors.red};
      default:
        return {'icon': Icons.notifications, 'label': action, 'color': Color(0xFF6B7280)};
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
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

        final docs = snapshot.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String action = data['action']?? '';
            final String noteTitle = data['noteTitle']?? 'Untitled';
            final Timestamp? timestamp = data['timestamp'];
            final String formattedTime = timestamp!= null
                ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate())
                : '';
            final info = _actionInfo(action);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFAF8F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (info['color'] as Color).withOpacity(0.15),
                    child: Icon(info['icon'] as IconData, color: info['color'] as Color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: noteTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                              ),
                              TextSpan(text: ' was ${info['label']}', style: TextStyle(color: Color(0xFF111827))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 90, color: Color(0xFF1E3A8A).withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            "No Activity Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            "Your note activity will show up here",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}