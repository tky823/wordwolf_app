import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'record.dart';
import 'customized_font.dart';
import 'master_discussion_room.dart';
import 'master_bulletin_room.dart';

class MasterResultRoomPage extends StatefulWidget {
  final String roomId;
  final Map<String, String> themes;

  MasterResultRoomPage({this.roomId, this.themes});

  @override
  State<StatefulWidget> createState() => _MasterResultRoomPageState();
}

class _MasterResultRoomPageState extends State<MasterResultRoomPage> {
  final String roomsString = 'rooms';
  final String membersString = 'members';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';
  final String timerString = 'timer';

  int _discussionTimeMinutes = 3;
  Map<String, int> setting = {
    'discussionTimeMinutesMin': 1,
    'discussionTimeMinutesMax': 10,
    'discussionTimeMinutesDefault': 5
  };

  String _roomId = '-1';
  String _uid = '-1';
  Map<String, String> _themes = {'citizen': '-1', 'werewolf': '-1'};
  List<Record> _records;

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
    activateMonitoringMembers();
    super.initState();
  }

  @override
  void dispose() {
    deactivateMonitoringMembers();
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

      final maxVotes = records[0];
      final recordWithMaxVotes =
          _records.where((record) => (record.votes == maxVotes));

      if (recordWithMaxVotes.length == 1) {
        columns.add(ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: Colors.orange, onPrimary: Colors.white),
            child: Text('結果を見る', style: smallerNormalFont),
            onPressed: () {
              deactivateMonitoringMembers();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => MasterBulletinRoomPage(
                          roomId: _roomId,
                          themes: _themes,
                        )),
                (_) => false,
              );
            }));
      } else {
        columns.add(Container(
          height: 60.0,
          padding: EdgeInsets.all(10.0),
          child: ListTile(
            leading: FloatingActionButton(
              heroTag: 'tag_plus',
              child: Icon(
                Icons.remove,
                color: Colors.white,
              ),
              backgroundColor: Colors.black,
              onPressed: () async {
                if (_discussionTimeMinutes >
                    setting['discussionTimeMinutesMin']) {
                  setState(() {
                    _discussionTimeMinutes -= 1;
                  });
                  final Map<String, int> roomData = {
                    'discussionTimeMinutes': _discussionTimeMinutes,
                  };

                  await FirebaseFirestore.instance
                      .collection(roomsString)
                      .doc(_roomId)
                      .update(roomData);
                }
              },
            ),
            title: Text(
              '$_discussionTimeMinutes 分',
              style: biggerNormalFont,
              textAlign: TextAlign.center,
            ),
            trailing: FloatingActionButton(
              heroTag: 'tag_minus',
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: Colors.black,
              onPressed: () async {
                if (_discussionTimeMinutes <
                    setting['discussionTimeMinutesMax']) {
                  setState(() {
                    _discussionTimeMinutes += 1;
                  });
                  final Map<String, int> roomData = {
                    'discussionTimeMinutes': _discussionTimeMinutes,
                  };

                  await FirebaseFirestore.instance
                      .collection(roomsString)
                      .doc(_roomId)
                      .update(roomData);
                }
              },
            ),
          ),
        ));

        columns.add(ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: Colors.orange, onPrimary: Colors.white),
          child: Text(
            'サドンテススタート',
          ),
          onPressed: () async {
            Map<String, dynamic> timeData = {
              'discussionEndTime':
                  DateTime.now().add(Duration(minutes: _discussionTimeMinutes))
            };

            await FirebaseFirestore.instance
                .collection(roomsString)
                .doc(_roomId)
                .update(timeData);

            deactivateMonitoringMembers();

            Map<String, bool> transitionsData = {
              'startsDiscussion': true,
              'endsVoting': false
            };

            await FirebaseFirestore.instance
                .collection(roomsString)
                .doc(_roomId)
                .collection(triggersString)
                .doc(transitionsString)
                .update(transitionsData);

            _records.forEach((record) async {
              Map<String, int> votesData = {
                'votes': 0,
              };

              await FirebaseFirestore.instance
                  .collection(roomsString)
                  .doc(_roomId)
                  .collection(membersString)
                  .doc(record.uid)
                  .update(votesData);
            });

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MasterDiscussionRoomPage(
                  roomId: _roomId,
                ),
              ),
              (_) => false,
            );
          },
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
}
