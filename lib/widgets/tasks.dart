import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get the uid of the currently logged in user
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _checkAndExpireTasks();
  }

  Future<void> _checkAndExpireTasks() async {
    final now = Timestamp.now();
    final querySnapshot = await _db
        .collection('tasks')
        .where('client_uid', isEqualTo: _uid)
        .where('expiry', isLessThan: now)
        .get();

    for (var doc in querySnapshot.docs) {
      if (doc['status'] != 'Expired') {
        doc.reference.update({'status': 'Expired'});
      }
    }
  }

  Stream<List<Task>> _loadTasks() {
    return _db
        .collection('tasks')
        .where('client_uid', isEqualTo: _uid)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      print('Tasks loaded: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  void _updateTaskStatus(String taskId, String newStatus) {
    _db.collection('tasks').doc(taskId).update({'status': newStatus});
  }

  // New Method: Determine the color based on task status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Assigned':
        return Colors.purple;
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.black; // Default color for unexpected status
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Task>>(
        stream: _loadTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Loading tasks...'));
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks available.'));
          }

          return SingleChildScrollView(
            child: ExpansionPanelList.radio(
              children: tasks.map<ExpansionPanelRadio>((Task task) {
                return ExpansionPanelRadio(
                  value: task.id,
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Text(
                        '${task.status} - ${DateFormat('dd/MM/yyyy hh:mm a').format(task.timestamp.toDate())}',
                        style: TextStyle(color: _getStatusColor(task.status)), 
                      ),
                    );
                  },
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(task.task),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Expires on: ${DateFormat('dd/MM/yyyy hh:mm a').format(task.expiry.toDate())}'),
                      ),
                      if (task.status == 'Assigned') ...[
                        Center(
                          child: ElevatedButton(
                            child: const Text('Accept'),
                            onPressed: () => _updateTaskStatus(task.id, 'In Progress'),
                          ),
                        ),
                      ] else if (task.status == 'In Progress') ...[
                        Center(
                          child: ElevatedButton(
                            child: const Text('Complete'),
                            onPressed: () => _updateTaskStatus(task.id, 'Completed'),
                          ),
                        ),
                      ] else if (task.status == 'Expired' || task.status == 'Completed') ...[
                        Center(
                          child: ElevatedButton(
                            child: const Text('Delete'),
                            onPressed: () => _db.collection('tasks').doc(task.id).delete(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String task;
  final Timestamp timestamp;
  final Timestamp expiry;
  final String status;

  Task({required this.id, required this.title, required this.task, required this.timestamp, required this.expiry, required this.status});

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'],
      task: data['task'],
      timestamp: data['timestamp'],
      expiry: data['expiry'],
      status: data['status'],
    );
  }
}
