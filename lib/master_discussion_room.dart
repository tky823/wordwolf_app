import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customized_font.dart';
import 'master_voting_room.dart';

class MasterDiscussionRoomPage extends StatefulWidget {
  final String roomId;
  MasterDiscussionRoomPage({this.roomId});

  @override
  State<StatefulWidget> createState() => _MasterDiscussionRoomPageState();
}

class _MasterDiscussionRoomPageState extends State<MasterDiscussionRoomPage> {
  final String roomsString = 'rooms';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String membersString = 'members';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';
  final String timerString = 'timer';

  final _formatter = DateFormat('m:ss');

  String _roomId = '-1';
  String _uid = '-1';
  String _genre = '-1';
  Map<String, String> _themes = {'citizen': '', 'werewolf': ''};
  String _themesId = '-1';
  String _theme = '';

  Timer _timer;
  DateTime _discussionEndTime;
  Duration _difference;
  String _currentString = '';

  @override
  void initState() {
    initializeFlutterFire();
    activateTimer();
    super.initState();
  }

  @override
  void dispose() {
    deactivateTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Text('ルーム $_roomId'),
      ),
      body: _buildBody(context),
      backgroundColor: Colors.orange[50],
    );
  }

  Widget _buildBody(BuildContext context) {
    return _buildDiscussionPage(context);
  }

  Widget _buildDiscussionPage(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'あなたのお題',
                style: smallerBoldFont,
              )),
          Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                _theme,
                style: biggerNormalFont,
              )),
          Text(
            '残り時間　$_currentString',
            style: biggerNormalFont,
          ),
        ],
      ),
    );
  }

  void initializeFlutterFire() async {
    User user = FirebaseAuth.instance.currentUser;

    _roomId = widget.roomId;

    DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .get();
    final roomData = roomSnapshot.data();
    final String werewolfUid = roomData['werewolfUid'];

    _genre = roomData['genreId'];
    _themesId = roomData['themesId'];
    _discussionEndTime = roomData['discussionEndTime']
        .toDate(); // .toDate(); // Timestamp -> Datetime

    DocumentSnapshot themesSnapshot = await FirebaseFirestore.instance
        .collection(genresString)
        .doc(_genre)
        .collection(themesString)
        .doc(_themesId)
        .get();

    final Map<String, dynamic> themesData = themesSnapshot.data();
    _themes['citizen'] = themesData['citizen'];
    _themes['werewolf'] = themesData['werewolf'];

    setState(() {
      _uid = user.uid;

      if (_uid == werewolfUid) {
        _theme = _themes['werewolf'];
      } else {
        _theme = _themes['citizen'];
      }

      _difference = _discussionEndTime.difference(DateTime.now());
      int _differenceMinutes = _difference.inMinutes;
      int _differenceSeconds = _difference.inSeconds - 60 * _differenceMinutes;

      _currentString = _formatter
          .format(DateTime(1, 1, 1, 1, _differenceMinutes, _differenceSeconds));
    });
  }

  void activateTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), _onTimer);
  }

  void deactivateTimer() {
    if (_timer != null) {
      _timer.cancel();
    }
  }

  void _onTimer(Timer timer) {
    _difference = _discussionEndTime.difference(DateTime.now());
    int differenceMinutes = _difference.inMinutes;
    int differenceInSeconds = _difference.inSeconds;
    int differenceSeconds = _difference.inSeconds - 60 * differenceMinutes;

    setState(() {
      _currentString = _formatter
          .format(DateTime(1, 1, 1, 1, differenceMinutes, differenceSeconds));
    });

    if (differenceInSeconds <= 0) {
      deactivateTimer();

      Map<String, bool> transitionData = {
        'startsDiscussion': false,
        'endsDiscussion': true,
      };

      FirebaseFirestore.instance
          .collection(roomsString)
          .doc(_roomId)
          .collection(triggersString)
          .doc(transitionsString)
          .update(transitionData);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MasterVotingRoomPage(
                    roomId: _roomId,
                    themes: _themes,
                  )));
    }
  }
}
