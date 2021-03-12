import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets.dart';

List<TaskItem> buildTaskItems(List<String> taskNames) {
  List<TaskItem> items = List();
  for (var i = 0; i < taskNames.length; i++) {
    items.add(
      TaskItem(i, taskNames[i], "", null, false),
    );
  }
  return items;
}

List<String> initTaskNames = [
  "Buy eggs",
  "Do laundry",
  "Buy more eggs",
  null,
];

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  List<TaskItem> _taskItems = buildTaskItems(initTaskNames);

  void _removeItem(int index) {
    final TaskItem item = _taskItems.removeAt(index);
    AnimatedListRemovedItemBuilder builder = (context, animation) {
      return _buildItem(item, index, animation);
    };
    listKey.currentState.removeItem(index, builder);
  }

  void _addItem(int index, String value) {
    listKey.currentState.insertItem(index);
    _taskItems.add(TaskItem(_taskItems.length, value, "", null, false));
  }

  Widget _buildItem(TaskItem item, int index, Animation animation) {
    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: animation,
      child: TaskItemWidget(
          item: item,
          onItemRemoved: () {
            _removeItem(index);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
            padding: EdgeInsets.all(13.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Image.asset('assets/images/tick.png', scale: 18),
                  Container(
                      padding: EdgeInsets.only(left: 8.0),
                      child: DropdownWidget())
                ]),
                Expanded(
                    child: Container(
                        padding: EdgeInsets.only(top: 30.0),
                        child: AnimatedList(
                          key: listKey,
                          initialItemCount: _taskItems.length,
                          itemBuilder: (context, index, animation) {
                            return _buildItem(
                                _taskItems[index], index, animation);
                          },
                        )))
              ],
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext context) {
                return NewTaskFormWidget(onFormSubmit: (String value) {
                  _addItem(_taskItems.length, value);
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
  }
}
