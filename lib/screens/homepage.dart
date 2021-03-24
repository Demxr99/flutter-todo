import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/task_list.dart';

class PanelItem {
  String timeframe;
  bool isExpanded;

  PanelItem({this.timeframe, this.isExpanded});
}

class OrganizedTaskList extends StatefulWidget {
  final String userId;
  final String selectedTaskListId;

  @override
  _OrganizedTaskListState createState() => _OrganizedTaskListState();

  OrganizedTaskList({this.userId, this.selectedTaskListId});
}

class _OrganizedTaskListState extends State<OrganizedTaskList> {
  final List<String> taskPanelItems = [
    "Overdue",
    "Today",
    "This week",
    "Future",
  ];

  DateTimeRange getDueDateRange(String timeframe) {
    final DateTime now = DateTime.now();
    switch (timeframe) {
      case "Overdue":
        return DateTimeRange(start: DateTime(1950), end: now);
        break;
      case "Today":
        return DateTimeRange(
            start: now, end: DateTime(now.year, now.month, now.day + 1));
        break;
      case "This week":
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day + 1),
            end: DateTime(now.year, now.month, now.day + 7));
        break;
      default:
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day + 7),
            end: DateTime(2100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SingleChildScrollView(
            child: Column(
      children: taskPanelItems.map((timeframe) {
        return TaskListWidget(
          userId: widget.userId,
          selectedTaskListId: widget.selectedTaskListId,
          dueDateRange: getDueDateRange(timeframe),
          title: timeframe,
        );
      }).toList(),
    )));
  }
}

class Homepage extends StatefulWidget {
  final String userId;
  final DateTimeRange dueDateRange;

  @override
  _HomepageState createState() => _HomepageState();

  Homepage({this.userId, this.dueDateRange});
}

class _HomepageState extends State<Homepage> {
  int _selectedTaskListIndex;

  void initState() {
    super.initState();
    _selectedTaskListIndex = 0;
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
                  padding: EdgeInsets.only(top: 13.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 10.0),
                        child: Row(children: [
                          Image.asset('assets/images/tick.png', scale: 18),
                          Container(
                              padding: EdgeInsets.only(left: 8.0),
                              child: DropdownWidget(
                                  tasklistsDocs: snapshot.data.docs,
                                  onTaskListSelected: onTaskListSelected))
                        ]),
                      ),
                      OrganizedTaskList(
                        userId: widget.userId,
                        selectedTaskListId:
                            snapshot.data.docs[_selectedTaskListIndex].id,
                      )
                    ],
                  )),
            ),
            bottomNavigationBar: BottomAppBar(
              shape: CircularNotchedRectangle(),
              child: IconTheme(
                data: IconThemeData(color: Colors.white),
                child: Wrap(
                  spacing: 20.0,
                  children: [
                    IconButton(
                        icon: Icon(
                          Icons.menu_outlined,
                        ),
                        onPressed: () {}),
                    IconButton(
                        icon: Icon(Icons.search_outlined), onPressed: () {}),
                    IconButton(
                        icon: Icon(Icons.calendar_today_outlined),
                        onPressed: () {})
                  ],
                ),
              ),
              color: Colors.green,
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
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
          );
        });
  }
}
