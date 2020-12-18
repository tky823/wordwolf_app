import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'error_page.dart';
import 'maintenance_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _digit = 6;
  final String roomsString = 'rooms';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String membersString = 'members';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';
  final String timerString = 'timer';

  bool _initialized = false;
  bool _error = false;
  bool _isMaintenance = true;

  String _username = 'ユーザ1';
  String _uid = '-1';
  String _roomId = '-1';
  String _password = '';

  bool _roomExists = false;
  bool _roomIsLocked = true;
  bool _isValidPassword = false;
  bool _nextPageTransitionIs = false;

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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

  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      _uid = userCredential.user.uid;

      final documentSnapshot = await FirebaseFirestore.instance
          .collection('notions')
          .doc('maintenance')
          .get();
      final data = documentSnapshot.data();

      setState(() {
        _isMaintenance = data['isValid'];
      });
    } catch (error) {
      setState(() {
        _error = true;
      });
    }
  }
}
