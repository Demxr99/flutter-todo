import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets.dart';

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  List<TaskItem> _taskItems;
  List<String> _taskNames;

  void initState() {
    super.initState();
    _taskNames = [
      "Buy eggs",
      "Do laundry",
      "Buy more eggs",
      null,
    ];
    _taskItems = buildTaskItems(_taskNames);
  }

  List<TaskItem> buildTaskItems(List<String> taskNames) {
    List<TaskItem> items = List();
    for (var i = 0; i < taskNames.length; i++) {
      items.add(
        TaskItem(i, taskNames[i], "", null, false),
      );
    }
    return items;
  }

  void _removeItem(int index) {
    AnimatedListRemovedItemBuilder builder = (context, animation) {
      return _buildItem(index, animation);
    };
    listKey.currentState.removeItem(index, builder);
  }

  Widget _buildItem(int index, Animation animation) {
    // return SlideTransition(
    //   position: Tween<Offset>(
    //     begin: const Offset(-1, 0),
    //     end: Offset(0, 0),
    //   ).animate(animation),
    //   child: TaskItemWidget(
    //       index: index,
    //       title: _taskItems[index].name,
    //       onItemRemoved: _removeItem),
    // );
    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: animation,
      child: TaskItemWidget(
          index: index,
          title: _taskItems[index].name,
          onItemRemoved: _removeItem),
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
                        child:
                            // TaskListWidget(taskItems: _taskItems ?? [], key: listKey),
                            AnimatedList(
                          key: listKey,
                          initialItemCount: _taskItems.length,
                          itemBuilder: (context, index, animation) {
                            return _buildItem(index, animation);
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
                  setState(() {
                    List<String> taskNames = List.from(_taskNames);
                    taskNames.add(value);

                    List<TaskItem> taskItems = buildTaskItems(taskNames);
                    _taskNames = taskNames;
                    _taskItems = taskItems;
                  });

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
