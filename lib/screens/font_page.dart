import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FontPage extends StatelessWidget {
  const FontPage({Key? key}) : super(key: key);

  final List<String> fontList = ['ComicNeue'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose a font'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 15.0,
        ),
      ),
    );
  }
}
