import 'package:countdown/models/countdown_event.dart';
import 'package:countdown/utilities/my_countdowns.dart';
import 'package:countdown/widgets/countdown_card_builder.dart';
import 'package:countdown/widgets/countdown_card_empty.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class AddCountdownPage extends StatefulWidget {
  const AddCountdownPage({Key? key}) : super(key: key);

  @override
  _AddCountdownPageState createState() => _AddCountdownPageState();
}

class _AddCountdownPageState extends State<AddCountdownPage> {
  String? textBox;
  DateTime? dateTime;
  Color? color;
  IconData? icon;

  final List<Color> colors = [
    const Color(0XFFBB84E7),
    const Color(0XFFA3C4F3),
    const Color(0XFF568D66),
    const Color(0XFFF15152),
    const Color(0XFFFF9500),
    const Color(0XFF0a9396),
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.grey,
    Colors.lightBlue,
    Colors.lightGreen,
  ];

  final List<IconData> icons = [
    Icons.calendar_today,
    Icons.celebration,
    Icons.baby_changing_station,
    Icons.cake,
    Icons.local_dining,
    Icons.icecream,
    Icons.holiday_village,
    Icons.hiking,
    Icons.sports,
    Icons.sports_football,
    Icons.sports_baseball,
    Icons.sports_basketball,
    Icons.sports_esports
  ];

  final modalShape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Add Countdown'),
        actions: [
          TextButton(
            onPressed: () {
              if (textBox != null && dateTime != null) {
                CountdownEvent event = CountdownEvent(
                  title: textBox!,
                  eventDate: dateTime!,
                  color: color,
                  icon: icon,
                );
                context.read<MyCountdowns>().addEvent(event);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CountdownCardBuilder(
              title: textBox,
              eventDate: dateTime,
              color: color,
              icon: icon,
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  textBox = value;
                });
              },
            ),
            TextButton(
              child: const Text('Select Date'),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                showCupertinoModalPopup(
                    context: context,
                    builder: (_) => Container(
                          height: 190,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: Column(
                            children: [
                              Container(
                                height: 180,
                                child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: DateTime.now(),
                                    onDateTimeChanged: (val) {
                                      setState(() {
                                        dateTime = val;
                                      });
                                    }),
                              ),
                            ],
                          ),
                        ));
              },
            ),
            TextButton(
              child: const Text('Select Color'),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: modalShape,
                  builder: (_) => SizedBox(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 8.0,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Select A Color',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: GridView.count(
                              padding: const EdgeInsets.fromLTRB(25, 15, 25, 0),
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              crossAxisCount: 5,
                              children: List.generate(colors.length, (index) {
                                return MaterialButton(
                                  minWidth: 25,
                                  height: 25,
                                  shape: const CircleBorder(),
                                  color: colors[index],
                                  elevation: 0,
                                  onPressed: () {
                                    setState(() {
                                      color = colors[index];
                                    });
                                  },
                                );
                              }),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text(
                'Select Icon',
              ),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: modalShape,
                  builder: (_) => SizedBox(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 8.0,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Select an Icon',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: GridView.count(
                              padding: const EdgeInsets.fromLTRB(25, 15, 25, 0),
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              crossAxisCount: 5,
                              children: List.generate(icons.length, (index) {
                                return IconButton(
                                  icon: Icon(icons[index]),
                                  onPressed: () {
                                    setState(() {
                                      icon = icons[index];
                                    });
                                  },
                                );
                              }),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
