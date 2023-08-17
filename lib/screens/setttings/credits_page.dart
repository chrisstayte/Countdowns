import 'package:flutter/material.dart';

class CreditsPage extends StatelessWidget {
  CreditsPage({Key? key}) : super(key: key);
  TextStyle nameStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
  TextStyle descriptionStyle = const TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Credits'),
        ),
        body: ListView(
          children: [
            Card(
              color: const Color(0XFFCCCCEE),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Text(
                      'MacKenzie M.',
                      style: nameStyle,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Fonts, Colors, Design',
                      style: descriptionStyle,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.indigo,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Text(
                      'Sarah S.',
                      style: nameStyle,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Colors, User Experience',
                      style: descriptionStyle,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.teal,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Text(
                      'Jeff R.',
                      style: nameStyle,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Fonts, Colors',
                      style: descriptionStyle,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.pink.shade100,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Text(
                      'Chris S.',
                      style: nameStyle,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Developer',
                      style: descriptionStyle,
                    ),
                  ],
                ),
              ),
            )
          ],
        ));
  }
}
