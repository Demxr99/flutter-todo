import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class TaskItem {
  int index;
  String id;
  String name;
  String description;
  DateTime dueDate;
  bool complete;

  TaskItem(this.index, this.id, this.name, this.description, this.dueDate,
      this.complete);
}

class TaskItemWidget extends StatefulWidget {
  final TaskItem item;
  final Function onItemRemoved;

  @override
  _TaskItemWidgetState createState() => _TaskItemWidgetState();

  TaskItemWidget({this.item, this.onItemRemoved});
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 22.0,
          horizontal: 8.0,
        ),
        child: Row(
          children: [
            Checkbox(
                value: _checked,
                onChanged: (value) {
                  setState(() {
                    _checked = true;
                    Timer timer =
                        new Timer(new Duration(milliseconds: 450), () {
                      widget.onItemRemoved();
                      _checked = false;
                    });
                  });
                }),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name ?? "(Unnamed Task)",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
                ),
                widget.item.description.isEmpty
                    ? Container()
                    : Text(
                        widget.item.description,
                        style: TextStyle(fontSize: 15.0, color: Colors.grey),
                      ),
              ],
            )
          ],
        ));
  }
}

class TaskListWidget extends StatefulWidget {
  final String userId;
  final String selectedTaskListId;

  @override
  _TaskListWidgetState createState() => _TaskListWidgetState();

  TaskListWidget({this.userId, this.selectedTaskListId});
}

class _TaskListWidgetState extends State<TaskListWidget> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

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

    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: animation,
      child: TaskItemWidget(
          item: TaskItem(index, item.id, item['title'], item['description'],
              item['due_date'].toDate(), item['complete']),
          onItemRemoved: completeTask),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query tasks = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('tasklists')
        .doc(widget.selectedTaskListId)
        .collection('tasks')
        .where('complete', isEqualTo: false)
        .orderBy('due_date');

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
            return Container(
                child: Center(
              child: Text("You have no current tasks. Add a new task below!"),
            ));
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
                  // TODO: Handle this case.
                  break;
              }
              index++;
            }
          }
          print("right here");
          print(snapshot.data.docs);

          return Expanded(
              child: Container(
                  padding: EdgeInsets.only(top: 30.0),
                  child: AnimatedList(
                    key: listKey,
                    initialItemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index, animation) {
                      return _buildItem(
                          snapshot.data.docs[index], index, animation);
                    },
                  )));
        });
  }
}
