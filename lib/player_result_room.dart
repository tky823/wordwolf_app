import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'record.dart';
import 'customized_font.dart';
import 'player_discussion_room.dart';
import 'player_bulletin_room.dart';

class PlayerResultRoomPage extends StatefulWidget {
  final String roomId;
  final Map<String, String> themes;

  PlayerResultRoomPage({this.roomId, this.themes});

  @override
  State<StatefulWidget> createState() => _PlayerResultRoomPageState();
}

class _PlayerResultRoomPageState extends State<PlayerResultRoomPage> {
  final String roomsString = 'rooms';
  final String membersString = 'members';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';
  final String timerString = 'timer';

  String _roomId = '-1';
  String _uid = '-1';
  String _werewolfUid = '-1';
  Map<String, String> _themes = {'citizen': '-1', 'werewolf': '-1'};
  List<Record> _records;

  Map<String, String> _genre = {'genreId': '', 'genreName': ''};
  int _discussionTimeMinutes = 3;

  StreamSubscription<QuerySnapshot> _triggersStreamSubscription;
  StreamSubscription<DocumentSnapshot> _roomStreamSubscription;
  StreamSubscription<QuerySnapshot> _membersStreamSubscription;

  void initializeFlutterFire() async {
    User user = FirebaseAuth.instance.currentUser;

    _roomId = widget.roomId;
    _themes = widget.themes;

    setState(() {
      _uid = user.uid;
    });
  }

  @override
  void initState() {
    initializeFlutterFire();
    activateMonitoringTriggers();
    activateMonitoringMembers();
    activateMonitoringRoom();
    super.initState();
  }

  @override
  void dispose() {
    deactivateMonitoringMembers();
    deactivateMonitoringMembers();
    deactivateMonitoringRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        leading: IconButton(icon: Icon(Icons.menu), onPressed: null),
        title: Text('ルーム $_roomId'),
      ),
      body: _buildBody(context),
      backgroundColor: Colors.orange[50],
    );
  }

  Widget _buildBody(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    var canvasHeight =
        size.height - padding.top - padding.bottom - kToolbarHeight;

    List<Widget> columns = [];

    columns.add(Container(
        padding: EdgeInsets.all(10.0),
        child: Text(
          '投票結果',
          style: smallerBoldFont,
        )));

    if (_records != null) {
      columns.add(
        LimitedBox(
            maxHeight: canvasHeight * 0.5,
            child: _buildList(context, _records)),
      );

      final records = _records.map((record) => record.votes).toSet().toList();
      records.sort((a, b) => b.compareTo(a));
      print(records);

      final maxVotes = records[0];
      final recordWithMaxVotes =
          _records.where((record) => (record.votes == maxVotes));

      if (recordWithMaxVotes.length == 1) {
        columns.add(RaisedButton(
            color: Colors.orange,
            textColor: Colors.white,
            child: Text('結果を見る', style: smallerNormalFont),
            onPressed: () {
              deactivateMonitoringMembers();
              deactivateMonitoringMembers();
              deactivateMonitoringRoom();

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PlayerBulletinRoomPage(
                            roomId: _roomId,
                            themes: _themes,
                          )));
            }));
      } else {
        columns.add(Container(
          height: 60.0,
          padding: EdgeInsets.all(10.0),
          child: ListTile(
            title: Text(
              '$_discussionTimeMinutes 分',
              style: biggerNormalFont,
              textAlign: TextAlign.center,
            ),
          ),
        ));
      }
    }

    return Center(
      child: Column(
        children: columns,
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Record> records) {
    return ListView(
      padding: EdgeInsets.all(10.0),
      children: records.map((data) => _memberItem(data)).toList(),
    );
  }

  Widget _memberItem(Record record) {
    final uid = record.uid;
    final name = record.name;
    final votes = record.votes;
    String titleText = '$name';

    if (_uid == uid) {
      titleText = titleText + '（あなた）';
    }

    return Card(
      color: Colors.orange[100],
      child: ListTile(
        title: Text(
          titleText,
          style: biggerNormalFont,
        ),
        trailing: Text('$votes'),
      ),
    );
  }

  void activateMonitoringMembers() {
    _membersStreamSubscription = FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .collection(membersString)
        .snapshots()
        .listen((snapshots) async {
      List<Record> records = snapshots.docs
          .map((documentSnapshot) => Record.fromSnapshot(documentSnapshot))
          .toList();
      records.sort((a, b) => b.votes.compareTo(a.votes));

      setState(() {
        _records = records;
      });
    });
  }

  void deactivateMonitoringMembers() {
    if (_membersStreamSubscription != null) {
      _membersStreamSubscription.cancel();
    }
  }

  void activateMonitoringTriggers() {
    _triggersStreamSubscription = FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .collection(triggersString)
        .snapshots()
        .listen((event) async {
      // TODO: Simplify trigger

      DocumentSnapshot transitionsSnapshot = await FirebaseFirestore.instance
          .collection(roomsString)
          .doc(_roomId)
          .collection(triggersString)
          .doc(transitionsString)
          .get();

      final data = transitionsSnapshot.data();

      if (data['startsDiscussion']) {
        deactivateMonitoringTriggers();
        deactivateMonitoringRoom();
        deactivateMonitoringMembers();

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerDiscussionRoomPage(
                roomId: _roomId,
              ),
            ));
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
}
