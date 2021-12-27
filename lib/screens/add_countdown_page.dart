import 'package:countdown/widgets/countdown_card_builder.dart';
import 'package:countdown/widgets/countdown_card_empty.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddCountdownPage extends StatefulWidget {
  const AddCountdownPage({Key? key}) : super(key: key);

  @override
  _AddCountdownPageState createState() => _AddCountdownPageState();
}

class _AddCountdownPageState extends State<AddCountdownPage> {
  String? textBox;
  DateTime? dateTime;
  Color? color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Add Countdown'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CountdownCardBuilder(
              title: textBox,
              eventDate: dateTime,
              color: color,
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
                  builder: (_) => Container(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              MaterialButton(
                                onPressed: () {
                                  setState(() {
                                    color = Colors.red;
                                  });
                                },
                                shape: const CircleBorder(),
                                color: Colors.red,
                                elevation: 0,
                              ),
                              MaterialButton(
                                onPressed: () {},
                                shape: const CircleBorder(),
                                color: Colors.blue,
                                elevation: 0,
                              ),
                              MaterialButton(
                                onPressed: () {},
                                shape: const CircleBorder(),
                                color: Colors.orange,
                                elevation: 0,
                              ),
                              MaterialButton(
                                onPressed: () {},
                                shape: const CircleBorder(),
                                color: Colors.purple,
                                elevation: 0,
                              ),
                            ],
                          ),
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
