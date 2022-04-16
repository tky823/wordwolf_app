import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customized_font.dart';
import 'error_page.dart';
import 'maintenance_page.dart';
import 'master_waiting_room.dart';
import 'player_waiting_room.dart';

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
                onPressed: () async {
                  await _makeRoom();
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: RaisedButton(
                child: Text('部屋に入る'),
                color: Colors.orange,
                textColor: Colors.white,
                onPressed: () async {
                  await _enterRoom();
                },
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

  Future<void> _existsRoom(String roomId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(roomsString)
        .doc(roomId)
        .get();

    Map<String, dynamic> data = snapshot.data();
    if (data == null) {
      _roomExists = false;
    } else {
      _roomExists = true;
    }
  }

  Future<void> _validatesEntrance(String roomId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(roomsString)
        .doc(roomId)
        .get();

    Map<String, dynamic> data = snapshot.data();
    if (data == null) {
      _roomIsLocked = false;
    } else {
      if (data['isLocked']) {
        _roomIsLocked = true;
      } else {
        _roomIsLocked = false;
      }
    }
  }

  Future<void> _validatesPassword(String inputPassword) async {
    if (!_roomExists) {
      _isValidPassword = false;
      return;
    }

    final DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .get();
    final data = snapshot.data();
    _isValidPassword = (inputPassword == data['password']);
  }

  Future<void> _makeRoom() async {
    await _showMakingRoomAlertDialog(context);

    if (_nextPageTransitionIs) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MasterWaitingRoomPage(
            roomId: _roomId,
          ),
        ),
        (_) => false,
      );
    }
  }

  Future<void> _enterRoom() async {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    _uid = userCredential.user.uid;
    print('uid: $_uid');

    await _showEntranceAlertDialog(context);

    if (_nextPageTransitionIs) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerWaitingRoomPage(
            roomId: _roomId,
          ),
        ),
      );
    }
  }

  Future<void> _showMakingRoomAlertDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20.0),
          title: Text('部屋の作成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: _username,
                decoration: InputDecoration(
                  labelText: 'ユーザ名',
                ),
                onChanged: (text) {
                  setState(() {
                    _username = text;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '部屋のID',
                ),
                onChanged: (text) {
                  setState(() {
                    _roomId = text;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('作成'),
              onPressed: () async {
                await _existsRoom(_roomId);

                Navigator.pop(context);

                if (_roomExists) {
                  showMakingRoomFailureAlertDialog(context);

                  print("$_roomId already exists.");
                  _nextPageTransitionIs = false;
                } else if (_roomId.length < 6) {
                  // TODO: Alert
                  print(
                      "$_roomId was chosen as room ID. Set more than 6 characters for room ID.");
                  _nextPageTransitionIs = false;
                } else {
                  print("Make new room $_roomId.");

                  _nextPageTransitionIs = true;

                  final random = math.Random();
                  final password = random
                      .nextInt(math.pow(10, _digit))
                      .toString()
                      .padLeft(_digit, '0');

                  Map<String, dynamic> roomData = {
                    'roomId': _roomId,
                    'password': password,
                    'masterUid': _uid,
                    'timestamp': Timestamp.now(),
                    'isLocked': false
                  };

                  await FirebaseFirestore.instance
                      .collection(roomsString)
                      .doc(_roomId)
                      .set(roomData);

                  Map<String, dynamic> userData = {
                    'uid': _uid,
                    'name': _username,
                    'votes': 0,
                  };

                  await FirebaseFirestore.instance
                      .collection(roomsString)
                      .doc(_roomId)
                      .collection(membersString)
                      .doc(_uid)
                      .set(userData);

                  Map<String, dynamic> transitionTriggerData = {
                    'startsDiscussion': false,
                    'endsDiscussion': false,
                    'endsVoting': false,
                  };

                  await FirebaseFirestore.instance
                      .collection(roomsString)
                      .doc(_roomId)
                      .collection(triggersString)
                      .doc(transitionsString)
                      .set(transitionTriggerData);
                }
              },
            ),
            FlatButton(
              child: Text('戻る'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEntranceAlertDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20.0),
          title: Text('既存の部屋に参加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: _username,
                decoration: InputDecoration(
                  labelText: 'ユーザ名',
                ),
                onChanged: (text) {
                  _username = text;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '部屋のID',
                ),
                onChanged: (text) {
                  setState(() {
                    _roomId = text;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'パスワード',
                ),
                onChanged: (text) {
                  setState(() {
                    _password = text;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('入室'),
              onPressed: () async {
                await _existsRoom(_roomId);
                await _validatesEntrance(_roomId);
                await _validatesPassword(_password);

                Navigator.pop(context);

                if (!_roomExists) {
                  showEnteringRoomFailureAlertDialog(context);

                  print("ルーム" + _roomId + "は存在しません");
                  _nextPageTransitionIs = false;
                  return;
                }

                if (_roomIsLocked) {
                  showEnteringRoomFailureAlertDialog(context);

                  print("ルーム" + _roomId + "に参加できません");
                  _nextPageTransitionIs = false;
                  return;
                }

                if (!_isValidPassword) {
                  showEnteringRoomFailureAlertDialog(context);

                  print("パスワードが間違っています");
                  _nextPageTransitionIs = false;
                  return;
                }

                _nextPageTransitionIs = true;

                Map<String, dynamic> userData = {
                  'uid': _uid,
                  'name': _username,
                  'votes': 0,
                };

                await FirebaseFirestore.instance
                    .collection(roomsString)
                    .doc(_roomId)
                    .collection(membersString)
                    .doc(_uid)
                    .set(userData);
              },
            ),
            FlatButton(
              child: Text('戻る'),
              onPressed: () {
                _nextPageTransitionIs = false;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showMakingRoomFailureAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20.0),
          title: Text('部屋の作成に失敗'),
          content: Container(
            child: Text(
              "ルーム" + _roomId + "はすでに存在しています．",
              style: smallerNormalFont,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('戻る'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showEnteringRoomFailureAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20.0),
          title: Text('入室に失敗'),
          content: Container(
            child: Text(
              "ルーム" + _roomId + "が存在しない，またはパスワードが間違っています．",
              style: smallerNormalFont,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('戻る'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
