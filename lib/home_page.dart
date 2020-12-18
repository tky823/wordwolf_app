import 'package:flutter/material.dart';

import 'error_page.dart';
import 'maintenance_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    bool _initialized = false;
    bool _error = false;
    bool _isMaintenance = true;

    if (_error) {
      print("_error");
      return ErrorPage();
    }

    if (!_initialized) {
      print("!_initialized");
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

    if (_isMaintenance) {
      return MaintenancePage();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ホーム'),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(20.0),
              child: RaisedButton(
                child: Text('部屋の作成'),
                color: Colors.orange,
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: RaisedButton(
                child: Text('部屋に入る'),
                color: Colors.orange,
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.orange[50],
    );
  }
}
