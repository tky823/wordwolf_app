import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customized_font.dart';
import 'record.dart';
import 'player_discussion_room.dart';

class PlayerWaitingRoomPage extends StatefulWidget {
  final String roomId;
  PlayerWaitingRoomPage({this.roomId});

  @override
  State<StatefulWidget> createState() => _PlayerWaitingRoomPageState();
}

class _PlayerWaitingRoomPageState extends State<PlayerWaitingRoomPage> {
  final String roomsString = 'rooms';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String membersString = 'members';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';

  String _roomId = '-1';
  String _uid = '-1';
  Map<String, String> _genre = {'genreId': '', 'genreName': ''};
  int _discussionTimeMinutes = 0;

  StreamSubscription<QuerySnapshot> _triggersStreamSubscription;
  StreamSubscription<DocumentSnapshot> _roomStreamSubscription;

  @override
  void initState() {
    initializeFlutterFire();
    activateMonitoringTriggers();
    activateMonitoringRoom();
    super.initState();
  }

  @override
  void dispose() {
    deactivateMonitoringTriggers();
    deactivateMonitoringRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    var canvasHeight =
        size.height - padding.top - padding.bottom - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Text('ルーム $_roomId'),
      ),
      body: Column(
        children: [
          Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                '参加者',
                style: biggerBoldFont,
              )),
          LimitedBox(
            maxHeight: canvasHeight * 0.4,
            child: _buildBody(context),
          ),
          Container(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'ジャンル',
              style: biggerBoldFont,
            ),
          ),
          Container(
            height: 60.0,
            padding: EdgeInsets.all(10.0),
            child: ListTile(
              title: Text(
                _genre['genreName'],
                style: biggerNormalFont,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            height: 60.0,
            padding: EdgeInsets.all(10.0),
            child: Text(
              '$_discussionTimeMinutes 分',
              style: biggerNormalFont,
              textAlign: TextAlign.center,
            ),
          ),
          RaisedButton(
            child: Text(
              '退室',
              style: smallerNormalFont,
            ),
            color: Colors.orange,
            textColor: Colors.white,
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance
                  .collection(roomsString)
                  .doc(_roomId)
                  .collection(membersString)
                  .doc(_uid)
                  .delete();
            },
          ),
        ],
      ),
      backgroundColor: Colors.orange[50],
    );
  }

  void initializeFlutterFire() {
    User user = FirebaseAuth.instance.currentUser;

    _roomId = widget.roomId;

    setState(() {
      _uid = user.uid;
    });
  }

  void activateMonitoringTriggers() {
    final CollectionReference triggersReference = FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .collection(triggersString);
    _triggersStreamSubscription =
        triggersReference.snapshots().listen((event) async {
      final DocumentSnapshot transitionsSnapshot =
          await triggersReference.doc(transitionsString).get();

      final transitionsData = transitionsSnapshot.data();

      if (transitionsData['startsDiscussion']) {
        deactivateMonitoringTriggers();
        deactivateMonitoringRoom();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDiscussionRoomPage(
              roomId: _roomId,
            ),
          ),
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

  void activateMonitoringRoom() {
    _roomStreamSubscription = FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .snapshots()
        .listen((snapshot) async {
      final data = snapshot.data();
      setState(() {
        _genre['genreName'] = data['genreName'];
        _discussionTimeMinutes = data['discussionTimeMinutes'];
      });
    });
  }

  void deactivateMonitoringRoom() {
    if (_roomStreamSubscription != null) {
      _roomStreamSubscription.cancel();
    }
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(roomsString)
          .doc(_roomId)
          .collection(membersString)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildList(context, snapshot.data.docs);
        }

        return LinearProgressIndicator();
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: EdgeInsets.all(10.0),
      children: snapshot.map((data) => _memberItem(data)).toList(),
    );
  }

  Widget _memberItem(DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Card(
      color: Colors.orange[100],
      child: ListTile(
        title: Text(
          record.name,
          style: biggerNormalFont,
        ),
      ),
    );
  }
}
