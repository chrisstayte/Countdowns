import 'package:countdown/models/countdown_event.dart';
import 'package:countdown/screens/settings_page.dart';
import 'package:countdown/utilities/my_countdowns.dart';
import 'package:countdown/widgets/countdown_card_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class AddCountdownPage extends StatefulWidget {
  const AddCountdownPage({Key? key}) : super(key: key);

  @override
  _AddCountdownPageState createState() => _AddCountdownPageState();
}

class _AddCountdownPageState extends State<AddCountdownPage> {
  String textBox = '';
  DateTime? dateTime;
  Color? color;
  IconData? icon;

  final rowHeight = 42.0;

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
    Colors.deepPurple,
    Colors.black,
    Colors.pink
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

  void showIconPicker() {
    showModalBottomSheet(
      context: context,
      shape: modalShape,
      builder: (_) => SizedBox(
        height: 400,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 8.0,
          ),
          child: Column(
            children: [
              const Text(
                'Select an Icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  }

  void showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: modalShape,
      builder: (_) => SizedBox(
        height: 450,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
          ),
          child: Column(
            children: [
              const Text(
                'Select A Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: GridView.count(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  crossAxisCount: 5,
                  children: List.generate(colors.length, (index) {
                    return GestureDetector(
                        onTap: () {
                          setState(() {
                            color = colors[index];
                          });
                        },
                        child: Container(
                          height: 25,
                          width: 25,
                          decoration: BoxDecoration(
                            color: colors[index],
                            shape: BoxShape.circle,
                          ),
                        ));
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                color: Colors.grey.shade100,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Done"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                )),
            SizedBox(
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
      ),
    );
  }

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
              if (textBox.isNotEmpty && dateTime != null) {
                CountdownEvent event = CountdownEvent(
                  title: textBox,
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
            const SizedBox(height: 10),
            SizedBox(
              height: rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  textBox.isEmpty ? const Text('Enter a name') : const Text(''),
                  Flexible(
                    child: TextField(
                      textCapitalization: TextCapitalization.words,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      decoration: const InputDecoration(
                        hintTextDirection: TextDirection.rtl,
                        border: InputBorder.none,
                        hintText: 'Name',
                      ),
                      onChanged: (value) {
                        setState(() {
                          textBox = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: Colors.grey.shade400),
                ),
              ),
              height: rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select a date"),
                  dateTime == null
                      ? IconButton(
                          onPressed: showDatePicker,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          icon: const Icon(Icons.chevron_right),
                        )
                      : GestureDetector(
                          onTap: showDatePicker,
                          child: Text(
                              "${dateTime?.month.toString()}/${dateTime?.day.toString()}/${dateTime?.year.toString()}"),
                        )
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: Colors.grey.shade400),
                ),
              ),
              height: rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select a color"),
                  IconButton(
                    onPressed: showColorPicker,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: Colors.grey.shade400),
                ),
              ),
              height: rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select an icon'),
                  IconButton(
                    onPressed: showIconPicker,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: const Icon(
                      Icons.chevron_right,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
