import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ワードウルフ',
      home: HomePage(),
    );
  }
}
