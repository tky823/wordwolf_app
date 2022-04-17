import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customized_font.dart';
import 'player_voting_room.dart';

class PlayerDiscussionRoomPage extends StatefulWidget {
  final String roomId;
  PlayerDiscussionRoomPage({this.roomId});

  @override
  State<StatefulWidget> createState() => _PlayerDiscussionRoomPageState();
}

class _PlayerDiscussionRoomPageState extends State<PlayerDiscussionRoomPage> {
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

  StreamSubscription<QuerySnapshot> _triggersStreamSubscription;

  Timer _timer;
  DateTime _discussionEndTime;
  Duration _difference;
  String _currentString = '';

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
    _discussionEndTime =
        roomData['discussionEndTime'].toDate(); // Timestamp -> Datetime

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

      DateFormat formatter = DateFormat('m:ss');

      _difference = _discussionEndTime.difference(DateTime.now());
      int _differenceMinutes = _difference.inMinutes;
      int _differenceSeconds = _difference.inSeconds - 60 * _differenceMinutes;

      _currentString = formatter
          .format(DateTime(1, 1, 1, 1, _differenceMinutes, _differenceSeconds));
    });

    activateTimer();
    activateMonitoringTriggers();
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  void dispose() {
    deactivateTimer();
    deactivateMonitoringTriggers();
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
      deactivateMonitoringTriggers();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => PlayerVotingRoomPage(
                  roomId: _roomId,
                  themes: _themes,
                )),
        (_) => false,
      );
    }
  }

  void activateMonitoringTriggers() {
    final CollectionReference triggersReference = FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .collection(triggersString);
    _triggersStreamSubscription =
        triggersReference.snapshots().listen((event) async {
      DocumentSnapshot transitionsSnapshot =
          await triggersReference.doc(transitionsString).get();

      final transitionsData = transitionsSnapshot.data();

      if (transitionsData['endsDiscussion']) {
        deactivateTimer();
        deactivateMonitoringTriggers();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => PlayerVotingRoomPage(
                    roomId: _roomId,
                    themes: _themes,
                  )),
          (_) => false,
        );
      }
    });
  }

  void deactivateMonitoringTriggers() {
    if (_triggersStreamSubscription != null) {
      _triggersStreamSubscription.cancel();
    }
  }
}
