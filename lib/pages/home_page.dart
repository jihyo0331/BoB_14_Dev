import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});
  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final User? _user = AuthService.currentUser;

  Future<void> _addAssignment() async {
    final titleCtrl = TextEditingController();
    final mentorNameCtrl = TextEditingController();
    final courseNameCtrl = TextEditingController();
    final mentorEmailCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DateTime? dueDate;
    final TextEditingController _dateTimeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    _dateTimeCtrl.clear();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('새 과제 추가'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '과제 제목'),
                  validator: (v) => v == null || v.isEmpty ? '제목을 입력하세요' : null,
                ),
                TextFormField(
                  controller: mentorNameCtrl,
                  decoration: const InputDecoration(labelText: '멘토 이름'),
                  validator: (v) =>
                      v == null || v.isEmpty ? '멘토 이름을 입력하세요' : null,
                ),
                TextFormField(
                  controller: courseNameCtrl,
                  decoration: const InputDecoration(labelText: '수업 이름'),
                  validator: (v) =>
                      v == null || v.isEmpty ? '수업 이름을 입력하세요' : null,
                ),
                TextFormField(
                  controller: mentorEmailCtrl,
                  decoration: const InputDecoration(labelText: '멘토 이메일'),
                  validator: (v) =>
                      v == null || v.isEmpty ? '이메일을 입력하세요' : null,
                ),
                TextFormField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: '과제 내용'),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? '내용을 입력하세요' : null,
                ),
                TextFormField(
                  controller: _dateTimeCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '마감일 및 시간',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        dueDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _dateTimeCtrl.text = DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(dueDate!);
                      }
                    }
                  },
                  validator: (v) => dueDate == null ? '마감일 및 시간을 선택하세요' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate() ||
                  dueDate == null ||
                  _user == null)
                return;
              await FirebaseFirestore.instance.collection('assignments').add({
                'assignmentTitle': titleCtrl.text,
                'mentorName': mentorNameCtrl.text,
                'courseName': courseNameCtrl.text,
                'mentorEmail': mentorEmailCtrl.text,
                'content': contentCtrl.text,
                'dueDate': Timestamp.fromDate(dueDate!),
                'submissions': {_user!.uid: false},
                'createdBy': _user!.uid,
              });
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('과제 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          docs.sort((a, b) {
            final aDate = (a['dueDate'] as Timestamp).toDate();
            final bDate = (b['dueDate'] as Timestamp).toDate();
            return aDate.compareTo(bDate);
          });
          if (docs.isEmpty) {
            return const Center(child: Text('등록된 과제가 없습니다'));
          }
          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final submissions =
                  data['submissions'] as Map<String, dynamic>? ?? {};
              final isSubmitted = submissions[_user!.uid] as bool? ?? false;
              final due = (data['dueDate'] as Timestamp).toDate();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 및 제출 체크박스
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['assignmentTitle'] ?? '',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Checkbox(
                            value: isSubmitted,
                            onChanged: (v) => d.reference.update({
                              'submissions.${_user!.uid}': v,
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 멘토 및 수업 정보
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text(data['mentorName'] ?? ''),
                          const SizedBox(width: 16),
                          const Icon(Icons.class_, size: 16),
                          const SizedBox(width: 4),
                          Text(data['courseName'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 멘토 이메일
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16),
                          const SizedBox(width: 4),
                          Text(data['mentorEmail'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 과제 내용
                      Text(
                        data['content'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      // 마감일 및 시간
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(due),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAssignment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
