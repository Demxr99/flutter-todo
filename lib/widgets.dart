import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class TaskListNameItem {
  int value;
  String name;

  TaskListNameItem(this.value, this.name);
}

class TaskItem {
  int index;
  String name;
  String description;
  DateTime dueDate;
  bool complete;

  TaskItem(
      this.index, this.name, this.description, this.dueDate, this.complete);
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
                Text(
                  "This is a test description",
                  style: TextStyle(fontSize: 15.0, color: Colors.grey),
                ),
              ],
            )
          ],
        ));
  }
}

class DropdownWidget extends StatefulWidget {
  final List<QueryDocumentSnapshot> tasklistsDocs;
  @override
  _DropdownWidgetState createState() => _DropdownWidgetState();

  DropdownWidget({this.tasklistsDocs});
}

class _DropdownWidgetState extends State<DropdownWidget> {
  List<TaskListNameItem> _dropdownItems = [
    TaskListNameItem(1, "My Tasks"),
    TaskListNameItem(2, "Assignments"),
    TaskListNameItem(3, "Work Tasks"),
  ];

  List<TaskListNameItem> buildDropDownItems(List<QueryDocumentSnapshot> docs) {
    List<TaskListNameItem> dropdownItems = [];
    for (int i = 0; i < docs.length; i++) {
      dropdownItems.add(TaskListNameItem(i, docs[i]['name']));
    }
    return dropdownItems;
  }

  List<DropdownMenuItem<TaskListNameItem>> _dropdownMenuItems;
  TaskListNameItem _selectedItem;

  @override
  void initState() {
    super.initState();
    _dropdownMenuItems = buildDropDownMenuItems(widget.tasklistsDocs);
    _selectedItem =
        _dropdownMenuItems.length > 0 ? _dropdownMenuItems[0].value : null;
  }

  List<DropdownMenuItem<TaskListNameItem>> buildDropDownMenuItems(
      List<QueryDocumentSnapshot> docs) {
    return docs.asMap().keys.toList().map((index) {
      return DropdownMenuItem(
        child: Container(
            padding: EdgeInsets.symmetric(vertical: 5.0),
            child: Text(
              docs[index]['name'],
              style: TextStyle(fontSize: 25.0),
            )),
        value: TaskListNameItem(index + 1, docs[index]['name']),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: DropdownButtonHideUnderline(
      child: DropdownButton(
        value: _selectedItem,
        items: _dropdownMenuItems,
        onChanged: (value) {
          setState(() {
            _selectedItem = value;
          });
        },
      ),
    ));
  }
}

class NewTaskFormWidget extends StatefulWidget {
  final Function onFormSubmit;

  @override
  _NewTaskFormWidgetState createState() => _NewTaskFormWidgetState();

  NewTaskFormWidget({this.onFormSubmit});
}

class _NewTaskFormWidgetState extends State<NewTaskFormWidget> {
  TextEditingController _controller;

  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: _controller,
              onSubmitted: (String value) {},
              decoration: InputDecoration(labelText: "Enter new task"),
            ),
            Container(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: () {
                      widget.onFormSubmit(_controller.text);
                    },
                    icon: Icon(Icons.check),
                    label: Text('Save')))
          ],
        ));
  }
}
