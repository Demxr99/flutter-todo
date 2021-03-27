import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/time_zone_util.dart';
import 'package:flutter_application_1/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/task_list.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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
  FlutterLocalNotificationsPlugin _fltrNotification;
  final TimeZone timeZone = TimeZone();

  Future notificationSelected(String payload) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("Notification : $payload"),
      ),
    );
  }

  Future _scheduleNotification(DateTime scheduledTime, String taskTitle) async {
    var androidDetails = new AndroidNotificationDetails(
        "task_id", "task_reminder", "Channel for task reminders",
        importance: Importance.max);
    var iSODetails = new IOSNotificationDetails();
    var generalNotificationDetails =
        new NotificationDetails(android: androidDetails, iOS: iSODetails);

    // The device's timezone.
    String timeZoneName = await timeZone.getTimeZoneName();

    // Find the 'current location'
    final location = await timeZone.getLocation(timeZoneName);

    final scheduledDate = tz.TZDateTime.from(scheduledTime, location);

    print("notification scheduled");
    print(scheduledDate);

    await _fltrNotification.zonedSchedule(1, "Task Reminder", taskTitle,
        scheduledDate, generalNotificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  void initState() {
    super.initState();
    _selectedTaskListIndex = 0;
    AndroidInitializationSettings androidInitilize =
        AndroidInitializationSettings('tick');
    IOSInitializationSettings iOSinitilize = IOSInitializationSettings();
    InitializationSettings initilizationSettings =
        InitializationSettings(android: androidInitilize, iOS: iOSinitilize);
    _fltrNotification = FlutterLocalNotificationsPlugin();
    _fltrNotification.initialize(initilizationSettings,
        onSelectNotification: notificationSelected);
  }

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

          Future<void> addTask(
              String title,
              String description,
              DateTime date,
              bool isRecurring,
              int selectedTimeAmount,
              String selectedTimeframe) {
            if (selectedTimeAmount > 0) {
              DateTime notifDate = DateTime(date.year, date.month, date.day,
                  date.hour, date.minute, date.second);
              switch (selectedTimeframe) {
                case "minutes":
                  notifDate = DateTime(date.year, date.month, date.day,
                      date.hour, date.minute - selectedTimeAmount, date.second);
                  break;
                case "hours":
                  notifDate = DateTime(date.year, date.month, date.day,
                      date.hour - selectedTimeAmount, date.minute, date.second);
                  break;
                case "days":
                  notifDate = DateTime(
                      date.year,
                      date.month,
                      date.day - selectedTimeAmount,
                      date.hour,
                      date.minute,
                      date.second);
                  break;
                case "weeks":
                  notifDate = DateTime(
                      date.year,
                      date.month,
                      date.day - (7 * selectedTimeAmount),
                      date.hour,
                      date.minute,
                      date.second);
                  break;
                default:
                  break;
              }
              _scheduleNotification(notifDate, title);
            }
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
                          String description,
                          DateTime date,
                          bool isRecurring,
                          int selectedTimeAmount,
                          String selectedTimeframe) {
                        addTask(title, description, date, isRecurring,
                            selectedTimeAmount, selectedTimeframe);
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
