import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/task_list.dart';

class Homepage extends StatefulWidget {
  final String userId;

  @override
  _HomepageState createState() => _HomepageState();

  Homepage({this.userId});
}

class _HomepageState extends State<Homepage> {
  int _selectedTaskListIndex;
  String _selectedTaskListId;

  void initState() {
    super.initState();
    _selectedTaskListIndex = 0;
    _selectedTaskListId = null;
  }

  void _addItem(int index, String value) {}

  void onTaskListSelected(int taskListIndex) {
    setState(() {
      _selectedTaskListIndex = taskListIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference tasklists = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('tasklists');

    print(_selectedTaskListIndex);

    return StreamBuilder<QuerySnapshot>(
        stream: tasklists.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
                body: SafeArea(
                    child: Center(
                        child: Container(
              child: CircularProgressIndicator(),
              padding: EdgeInsets.symmetric(horizontal: 50.0),
            ))));
          }

          CollectionReference tasks = FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('tasklists')
              .doc(snapshot.data.docs[_selectedTaskListIndex].id)
              .collection('tasks');

          Future<void> addTask(String title, String description, DateTime date,
              bool isRecurring) {
            return tasks
                .add({
                  'title': title,
                  'description': description,
                  'due_date': date,
                  'complete': false,
                  'recurring': isRecurring
                })
                .then((value) => print('Task added'))
                .catchError((error) => print("Failed to add task: $error"));
          }

          return Scaffold(
            body: SafeArea(
              child: Container(
                  padding: EdgeInsets.all(13.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(children: [
                        Image.asset('assets/images/tick.png', scale: 18),
                        Container(
                            padding: EdgeInsets.only(left: 8.0),
                            child: DropdownWidget(
                                tasklistsDocs: snapshot.data.docs,
                                onTaskListSelected: onTaskListSelected))
                      ]),
                      TaskListWidget(
                          userId: widget.userId,
                          selectedTaskListId:
                              snapshot.data.docs[_selectedTaskListIndex].id)
                    ],
                  )),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet<void>(
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext context) {
                      return NewTaskFormWidget(onFormSubmit: (String title,
                          String description, DateTime date, bool isRecurring) {
                        addTask(title, description, date, isRecurring);
                        Navigator.of(context).pop();
                      });
                    });
              },
              child: Image.asset(
                'assets/images/add_task.png',
                color: Colors.white,
              ),
              backgroundColor: Colors.green,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        });
  }
}
