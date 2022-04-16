import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'record.dart';
import 'customized_font.dart';
import 'master_result_room.dart';

class MasterVotingRoomPage extends StatefulWidget {
  final String roomId;
  final Map<String, String> themes;

  MasterVotingRoomPage({this.roomId, this.themes});

  @override
  State<StatefulWidget> createState() => _MasterVotingRoomPageState();
}

class _MasterVotingRoomPageState extends State<MasterVotingRoomPage> {
  final String roomsString = 'rooms';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String membersString = 'members';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';
  final String timerString = 'timer';

  String _roomId = '-1';
  String _uid = '-1';
  String _suspicionId;
  Map<String, String> _themes = {'citizen': '-1', 'werewolf': '-1'};

  StreamSubscription<QuerySnapshot> _membersStreamSubscription;
  bool _isVoted = false;

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

    if (_isVoted) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'みんなの投票を待っています',
                style: smallerNormalFont,
              ))
        ],
      ));
    }

    return Column(children: [
      Container(
          padding: EdgeInsets.all(10.0),
          child: Text(
            '人狼だと思う人を選んでください．',
            style: smallerBoldFont,
          )),
      LimitedBox(
        maxHeight: canvasHeight * 0.6,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(roomsString)
              .doc(_roomId)
              .collection(membersString)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return LinearProgressIndicator();
            }
            return _buildVoteList(context, snapshot.data.docs);
          },
        ),
      ),
      RaisedButton(
        child: const Text('投票を送信'),
        color: Colors.orange,
        textColor: Colors.white,
        onPressed: _pushVote,
      ),
    ]);
  }

  Widget _buildVoteList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: EdgeInsets.all(10.0),
      children: snapshot.map((data) => _buildMemberItem(data)).toList(),
    );
  }

  Widget _buildMemberItem(DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    final String uid = record.uid;
    final String name = record.name;
    final bool chosen = (uid == _suspicionId);

    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          chosen ? Icons.check_box : Icons.check_box_outline_blank,
          color: chosen ? Colors.blue : null,
        ),
        title: Text(
          name,
          style: biggerNormalFont,
        ),
        onTap: () {
          setState(() {
            if (chosen) {
              _suspicionId = null;
            } else {
              _suspicionId = uid;
            }
          });
        },
      ),
    );
  }

  void _pushVote() {
    if (_suspicionId == null) {
      return;
    }

    setState(() {
      _isVoted = true;
    });

    Map<String, dynamic> voteData = {
      'votes': FieldValue.increment(1),
    };

    FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .collection(membersString)
        .doc(_suspicionId)
        .update(voteData);
  }

  void activateMonitoringMembers() {
    _membersStreamSubscription = FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .collection(membersString)
        .snapshots()
        .listen((event) async {
      int totalVotes = 0;
      int totalMembers = 0;

      event.docs.forEach((snapshot) {
        final data = snapshot.data();

        totalVotes += data['votes'];
        totalMembers += 1;
      });

      if (totalVotes == totalMembers) {
        deactivateMonitoringMembers();

        Map<String, bool> transitionsData = {
          'endsDiscussion': false,
          'endsVoting': true,
        };

        await FirebaseFirestore.instance
            .collection(roomsString)
            .doc(_roomId)
            .collection(triggersString)
            .doc(transitionsString)
            .update(transitionsData);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => MasterResultRoomPage(
                    roomId: _roomId,
                    themes: _themes,
                  )),
          (_) => false,
        );
      }
    });
  }

  void deactivateMonitoringMembers() {
    if (_membersStreamSubscription != null) {
      _membersStreamSubscription.cancel();
    }
  }
}
