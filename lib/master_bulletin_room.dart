import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'record.dart';
import 'customized_font.dart';

class MasterBulletinRoomPage extends StatefulWidget {
  final String roomId;
  final Map<String, String> themes;
  MasterBulletinRoomPage({this.roomId, this.themes});

  @override
  State<StatefulWidget> createState() => _MasterBulletinRoomPageState();
}

class _MasterBulletinRoomPageState extends State<MasterBulletinRoomPage> {
  final String roomsString = 'rooms';
  final String membersString = 'members';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';
  final String timerString = 'timer';
  final String uidString = 'uid';
  final String citizenString = 'citizen';
  final String werewolfString = 'werewolf';

  String _roomId = '-1';
  String _uid = '-1';
  String _werewolfUid = '-1';
  Map<String, String> _themes = {'citizen': '-1', 'werewolf': '-1'};
  String _theme = '-1';

  void initializeFlutterFire() async {
    User user = FirebaseAuth.instance.currentUser;

    _roomId = widget.roomId;
    _themes = widget.themes;

    DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .get();
    final roomData = roomSnapshot.data();

    setState(() {
      _uid = user.uid;
      _werewolfUid = roomData['werewolfUid'];

      if (_uid == _werewolfUid) {
        _theme = _themes[werewolfString];
      } else {
        _theme = _themes[citizenString];
      }
    });
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
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
    final String citizenTheme = _themes[citizenString];
    final String werewolfTheme = _themes[werewolfString];

    return Center(
      child: Column(
        children: [
          Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                '人狼：$werewolfTheme',
                style: smallerBoldFont,
              )),
          LimitedBox(
            maxHeight: canvasHeight * 0.2,
            child: _buildWerewolfList(context),
          ),
          Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                '市民：$citizenTheme',
                style: smallerBoldFont,
              )),
          LimitedBox(
            maxHeight: canvasHeight * 0.4,
            child: _buildCitizenList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWerewolfList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(roomsString)
          .doc(_roomId)
          .collection(membersString)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print("Found data");
          final documentSnapshot = snapshot.data.docs;
          List<QueryDocumentSnapshot> werewolfDocumentSnapshot = [];
          documentSnapshot.forEach((snapshot) {
            final data = snapshot.data();
            if (_werewolfUid == data[uidString]) {
              werewolfDocumentSnapshot.add(snapshot);
            }
          });

          return ListView(
              padding: EdgeInsets.all(10.0),
              children: werewolfDocumentSnapshot.map((data) {
                return _memberItem(data);
              }).toList());
        }
        print("No data");
        return LinearProgressIndicator();
      },
    );
  }

  Widget _buildCitizenList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(roomsString)
          .doc(_roomId)
          .collection(membersString)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print("Found data");
          final documentSnapshot = snapshot.data.docs;
          List<QueryDocumentSnapshot> citizenDocumentSnapshot = [];
          documentSnapshot.forEach((snapshot) {
            final data = snapshot.data();

            if (_werewolfUid != data[uidString]) {
              citizenDocumentSnapshot.add(snapshot);
            }
          });

          return ListView(
              padding: EdgeInsets.all(10.0),
              children: citizenDocumentSnapshot.map((data) {
                return _memberItem(data);
              }).toList());
        }
        print("No data");
        return LinearProgressIndicator();
      },
    );
  }

  Widget _memberItem(DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);
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
}
