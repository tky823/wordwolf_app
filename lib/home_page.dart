import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text('ワードウルフ'),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
