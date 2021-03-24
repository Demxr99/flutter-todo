import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:intl/intl.dart';

class TaskItem {
  int index;
  String id;
  String name;
  String description;
  DateTime dueDate;
  bool complete;
  String timeframe;

  TaskItem(this.index, this.id, this.name, this.description, this.dueDate,
      this.complete, this.timeframe);
}

class TaskItemWidget extends StatefulWidget {
  final TaskItem item;
  final Function onTaskCompleted;
  final Function onTaskDeleted;

  @override
  _TaskItemWidgetState createState() => _TaskItemWidgetState();

  TaskItemWidget({this.item, this.onTaskCompleted, this.onTaskDeleted});
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = false;
  }

  String getDueDateFormat(String timeframe) {
    switch (timeframe) {
      case "Overdue":
        return 'M/d, h:mm a';
        break;
      case "Today":
        return 'h:mm a';
        break;
      case "This week":
        return 'E, h:mm a';
        break;
      default:
        return 'E, MMM d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 8.0,
        ),
        child: Column(children: [
          Dismissible(
              key: UniqueKey(),
              onDismissed: (DismissDirection direction) {
                widget.onTaskDeleted();
              },
              background: Container(color: Colors.red),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Checkbox(
                        value: _checked,
                        onChanged: (value) {
                          setState(() {
                            _checked = true;
                            Timer timer =
                                new Timer(new Duration(milliseconds: 450), () {
                              widget.onTaskCompleted();
                              _checked = false;
                            });
                          });
                        }),
                  ),
                  Expanded(
                      flex: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name ?? "(Unnamed Task)",
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w500),
                          ),
                          widget.item.description.isEmpty
                              ? Container()
                              : Text(
                                  widget.item.description,
                                  style: TextStyle(
                                      fontSize: 15.0, color: Colors.grey),
                                ),
                        ],
                      )),
                  Expanded(
                    flex: 6,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)))),
                      onPressed: null,
                      child: Text(
                          DateFormat(getDueDateFormat(widget.item.timeframe))
                              .format(widget.item.dueDate)),
                    ),
                  ),
                ],
              )),
          // const Divider(
          //   height: 50,
          //   thickness: 2,
          //   indent: 20,
          //   endIndent: 20,
          // )
        ]));
  }
}

class TaskListWidget extends StatefulWidget {
  final String userId;
  final String selectedTaskListId;
  final DateTimeRange dueDateRange;
  final String title;

  @override
  _TaskListWidgetState createState() => _TaskListWidgetState();

  TaskListWidget(
      {this.userId, this.selectedTaskListId, this.dueDateRange, this.title});
}

class _TaskListWidgetState extends State<TaskListWidget> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  final List<int> items = [];

  Widget _buildItem(
      QueryDocumentSnapshot item, int index, Animation animation) {
    CollectionReference tasks = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('tasklists')
        .doc(widget.selectedTaskListId)
        .collection('tasks');

    Future<void> completeTask() {
      listKey.currentState.removeItem(index, (context, animation) {
        return _buildItem(item, index, animation);
      });
      return tasks
          .doc(item.id)
          .update({'complete': true})
          .then((value) => print('Task complete'))
          .catchError((error) => print("Failed to complete task: $error"));
    }

    Future<void> deleteTask() {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Task deleted"),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.blue,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            return tasks
                .add({
                  'title': item['title'],
                  'description': item['description'],
                  'due_date': item['due_date'].toDate(),
                  'complete': item['complete'],
                  'recurring': item['recurring']
                })
                .then((value) => print('Task added'))
                .catchError((error) => print("Failed to add task: $error"));
          },
        ),
      ));

      return tasks
          .doc(item.id)
          .delete()
          .then((value) => print('Task deleted'))
          .catchError((error) => print("Failed to delete task: $error"));
    }

    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: animation,
      child: TaskItemWidget(
          item: TaskItem(index, item.id, item['title'], item['description'],
              item['due_date'].toDate(), item['complete'], widget.title),
          onTaskCompleted: completeTask,
          onTaskDeleted: deleteTask),
    );
  }

  Color getColorFromTimeFrame(String timeframe) {
    switch (timeframe) {
      case "Overdue":
        return Colors.red.shade400;
        break;
      case "Today":
        return Colors.blue;
        break;
      case "This week":
        return Colors.green;
        break;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.dueDateRange.start);
    print(widget.dueDateRange.end);
    Query tasks = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('tasklists')
        .doc(widget.selectedTaskListId)
        .collection('tasks')
        .where('complete', isEqualTo: false)
        .where('due_date', isLessThan: widget.dueDateRange.end)
        .where('due_date', isGreaterThan: widget.dueDateRange.start)
        .orderBy('due_date');

    print("we made it here");

    return StreamBuilder<QuerySnapshot>(
        stream: tasks.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Container(
              child: CircularProgressIndicator(),
              padding: EdgeInsets.symmetric(horizontal: 50.0),
            ));
          }

          if (snapshot.data.docs.isEmpty) {
            return Container();
          }

          print(snapshot.data.docChanges);
          if (listKey.currentState != null) {
            for (final change in snapshot.data.docChanges) {
              print(change.type);
              int index = 0;
              switch (change.type) {
                case DocumentChangeType.added:
                  listKey.currentState.insertItem(index);
                  print("document added");
                  break;
                case DocumentChangeType.modified:
                  // TODO: Handle this case.
                  break;
                case DocumentChangeType.removed:
                  listKey.currentState.removeItem(index, (context, animation) {
                    return _buildItem(
                        snapshot.data.docs[index], index, animation);
                  });
                  break;
              }
              index++;
            }
          }

          print(widget.dueDateRange.start);
          print(snapshot.data.docs);

          return Container(
              padding: EdgeInsets.only(top: 30.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: EdgeInsets.only(left: 22.0),
                        child: Text(widget.title,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 22.0,
                                color: getColorFromTimeFrame(widget.title),
                                fontWeight: FontWeight.bold))),
                    AnimatedList(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      key: listKey,
                      initialItemCount: snapshot.data.docs.length,
                      itemBuilder: (context, index, animation) {
                        return _buildItem(
                            snapshot.data.docs[index], index, animation);
                      },
                    ),
                    widget.title != "Future"
                        ? Divider(
                            height: 0,
                            thickness: 2,
                            // indent: 20,
                            // endIndent: 20,
                          )
                        : Container()
                  ]));
        });
  }
}
