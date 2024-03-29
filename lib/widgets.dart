import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TaskListNameItem {
  int value;
  String name;

  TaskListNameItem(this.value, this.name);
}

class DropdownWidget extends StatefulWidget {
  final List<QueryDocumentSnapshot> tasklistsDocs;
  final Function onTaskListSelected;
  @override
  _DropdownWidgetState createState() => _DropdownWidgetState();

  DropdownWidget({this.tasklistsDocs, this.onTaskListSelected});
}

class _DropdownWidgetState extends State<DropdownWidget> {
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
        value: TaskListNameItem(index, docs[index]['name']),
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
          if (value.value != _selectedItem.value) {
            setState(() {
              _selectedItem = value;
            });
            widget.onTaskListSelected(value.value);
          }
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
  TextEditingController _taskTitleController;
  TextEditingController _taskDescriptionController;
  bool _isDescriptionSelected;
  bool _isDueDateAdded;
  FocusNode _taskDescriptionNode;
  DateTime _dueDate;
  bool _isRecurring;
  bool _isNotifications;
  String _selectedTimeFreq;
  int _selectedTimeAmount;
  TextEditingController _timeAmountController;

  final List<String> timeFreqList = ['minutes', 'hours', 'days', 'weeks'];

  void initState() {
    super.initState();
    _taskTitleController = TextEditingController();
    _taskDescriptionController = TextEditingController();
    _taskDescriptionNode = new FocusNode();
    _isDescriptionSelected = false;
    _isDueDateAdded = false;
    _dueDate = null;
    _isRecurring = false;
    _isNotifications = false;
    _selectedTimeFreq = 'hours';
    _selectedTimeAmount = 0;
    _timeAmountController = TextEditingController();
  }

  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _taskDescriptionNode.dispose();
    _timeAmountController.dispose();
    super.dispose();
  }

  _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
      _selectTime(context);
    }
  }

  _selectTime(BuildContext context) async {
    final TimeOfDay picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (picked != null) {
      _dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day,
          picked.hour, picked.minute);
      _isDueDateAdded = true;
    }
  }

  Future<void> _showNotificationsDialog() async {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Set Task Reminder'),
            content: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Container(
                          width: 50.0,
                          padding: EdgeInsets.only(right: 8.0),
                          child: TextField(
                            controller: _timeAmountController,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[1-9][0-9]*'))
                            ],
                          )),
                      Expanded(
                          child: DropdownButtonFormField(
                              value: _selectedTimeFreq,
                              onChanged: (value) {
                                setState(() {
                                  _selectedTimeFreq = value;
                                });
                              },
                              items: timeFreqList
                                  .map(
                                    (label) => DropdownMenuItem(
                                      child: Text(label),
                                      value: label,
                                    ),
                                  )
                                  .toList()))
                    ]),
                    Container(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('before due date.')),
                  ]),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      _timeAmountController.text = _selectedTimeAmount == 0
                          ? null
                          : _selectedTimeAmount.toString();
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel')),
              TextButton(
                  onPressed: () {
                    setState(() {
                      _isNotifications = _timeAmountController.text.isNotEmpty;
                      _selectedTimeAmount =
                          _timeAmountController.text.isNotEmpty
                              ? int.parse(_timeAmountController.text)
                              : 0;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Confirm')),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    print(_timeAmountController.text);
    print(_selectedTimeFreq);
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: _taskTitleController,
              onSubmitted: (String value) {},
              decoration: InputDecoration(labelText: "Enter new task"),
            ),
            _isDescriptionSelected
                ? TextField(
                    focusNode: _taskDescriptionNode,
                    controller: _taskDescriptionController,
                    onSubmitted: (String value) {},
                    decoration:
                        InputDecoration(labelText: "Enter task description"),
                  )
                : Container(),
            Container(
                padding: EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(
                          Icons.description_outlined,
                          color: _isDescriptionSelected
                              ? Colors.blueAccent
                              : Colors.grey,
                          size: 28.0,
                        ),
                        onPressed: () {
                          _taskDescriptionNode.requestFocus();
                          setState(() {
                            _isDescriptionSelected = !_isDescriptionSelected;
                          });
                        }),
                    IconButton(
                        icon: Icon(
                          Icons.event_available_outlined,
                          color:
                              _isDueDateAdded ? Colors.blueAccent : Colors.grey,
                          size: 28.0,
                        ),
                        onPressed: () {
                          _selectDate(context);
                        }),
                    _isDueDateAdded
                        ? Row(children: [
                            OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)))),
                                onPressed: () {
                                  setState(() {
                                    _isDueDateAdded = false;
                                  });
                                },
                                icon: Icon(Icons.clear_outlined),
                                label: Text(DateFormat('MMM d, h:mm a')
                                    .format(_dueDate))),
                            IconButton(
                                icon: Icon(
                                  Icons.notification_important_outlined,
                                  size: 28.0,
                                ),
                                color: _isNotifications
                                    ? Colors.blueAccent
                                    : Colors.grey,
                                onPressed: () {
                                  setState(() {
                                    _showNotificationsDialog();
                                  });
                                }),
                            IconButton(
                                icon: Icon(
                                  Icons.repeat_outlined,
                                  size: 28,
                                ),
                                color: _isRecurring
                                    ? Colors.blueAccent
                                    : Colors.grey,
                                onPressed: () {
                                  setState(() {
                                    _isRecurring = !_isRecurring;
                                  });
                                })
                          ])
                        : Container()
                  ],
                )),
            Container(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    widget.onFormSubmit(
                        _taskTitleController.text,
                        _isDescriptionSelected
                            ? _taskDescriptionController.text
                            : "",
                        _dueDate,
                        _isRecurring,
                        _selectedTimeAmount,
                        _selectedTimeFreq);
                  },
                  label: Text('Save'),
                  icon: Icon(Icons.check),
                ))
          ],
        ));
  }
}
