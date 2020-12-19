import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customized_font.dart';
import 'record.dart';
import 'master_discussion_room.dart';

class MasterWaitingRoomPage extends StatefulWidget {
  final String roomId;
  MasterWaitingRoomPage({this.roomId});

  @override
  State<StatefulWidget> createState() => _MasterWaitingRoomPageState();
}

class _MasterWaitingRoomPageState extends State<MasterWaitingRoomPage> {
  final String roomsString = 'rooms';
  final String genresString = 'genres';
  final String themesString = 'themes';
  final String membersString = 'members';
  final String triggersString = 'triggers';
  final String transitionsString = 'transitions';

  String _roomId = '-1';
  String _uid = '-1';
  String _password = '';
  List<Record> _memberRecords = [];
  Map<String, String> _genre = {'genreId': '', 'genreName': ''};
  int _genreIndex = 0;
  List<Map<String, String>> _genres = [];
  int _discussionTimeMinutes = 3;
  Map<String, int> setting = {
    'discussionTimeMinutesMin': 1,
    'discussionTimeMinutesMax': 10,
    'discussionTimeMinutesDefault': 5
  };

  StreamSubscription<QuerySnapshot> _membersStreamSubscription;

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
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    var canvasHeight =
        size.height - padding.top - padding.bottom - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        leading: IconButton(icon: Icon(Icons.menu), onPressed: null),
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
            child: Text(
              'ジャンル',
              style: biggerBoldFont,
            ),
          ),
          Container(
            height: 60.0,
            padding: EdgeInsets.all(10.0),
            child: ListTile(
              leading: FloatingActionButton(
                heroTag: 'tag_back',
                child: Icon(Icons.arrow_back),
                backgroundColor: Colors.black,
                onPressed: () async {
                  setState(() {
                    _genreIndex = (_genreIndex - 1) % _genres.length;
                    _genre = _genres[_genreIndex];
                  });
                  final Map<String, String> roomData = {
                    'genreId': _genre['genreId'],
                    'genreName': _genre['genreName']
                  };

                  await FirebaseFirestore.instance
                      .collection(roomsString)
                      .doc(_roomId)
                      .update(roomData);
                },
              ),
              title: Text(
                _genre['genreName'],
                style: biggerNormalFont,
                textAlign: TextAlign.center,
              ),
              trailing: FloatingActionButton(
                heroTag: 'tag_next',
                child: Icon(Icons.arrow_forward),
                backgroundColor: Colors.black,
                onPressed: () async {
                  setState(() {
                    _genreIndex = (_genreIndex + 1) % _genres.length;
                    _genre = _genres[_genreIndex];
                  });
                  final Map<String, String> roomData = {
                    'genreId': _genre['genreId'],
                    'genreName': _genre['genreName']
                  };

                  await FirebaseFirestore.instance
                      .collection(roomsString)
                      .doc(_roomId)
                      .update(roomData);
                },
              ),
            ),
          ),
          Container(
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
          ),
          Container(
            padding:
                EdgeInsets.only(left: 5.0, right: 5.0, top: 20.0, bottom: 5.0),
            child: Text(
              '部屋のID：$_roomId',
              style: smallerNormalFont,
            ),
          ),
          Container(
            padding: EdgeInsets.all(5.0),
            child: Text(
              'パスワード：$_password',
              style: smallerNormalFont,
            ),
          ),
          RaisedButton(
            child: Text(
              'スタート',
              style: smallerNormalFont,
            ),
            color: Colors.orange,
            textColor: Colors.white,
            onPressed: () async {
              final random = math.Random();

              String werewolfUid =
                  _memberRecords[random.nextInt(_memberRecords.length)].uid;

              Map<String, dynamic> roomData = {
                'werewolfUid': werewolfUid,
                'isLocked': true
              };

              Map<String, dynamic> themeData =
                  await getRandomThemeInfo(_genre['genreId']);

              roomData.addAll(themeData);

              Map<String, dynamic> timeData = {
                'discussionEndTime': DateTime.now()
                    .add(Duration(minutes: _discussionTimeMinutes))
              };

              roomData.addAll(timeData);

              await FirebaseFirestore.instance
                  .collection(roomsString)
                  .doc(_roomId)
                  .update(roomData);

              deactivateMonitoringMembers();

              Map<String, bool> transitionsData = {
                'startsDiscussion': true,
              };

              await FirebaseFirestore.instance
                  .collection(roomsString)
                  .doc(_roomId)
                  .collection(triggersString)
                  .doc(transitionsString)
                  .update(transitionsData);

              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MasterDiscussionRoomPage(
                      roomId: _roomId,
                    ),
                  ));
            },
          ),
        ],
      ),
      backgroundColor: Colors.orange[50],
    );
  }

  void initializeFlutterFire() async {
    User user = FirebaseAuth.instance.currentUser;

    _roomId = widget.roomId;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .get();

    final data = snapshot.data();
    final genres = await getGenreList();

    setState(() {
      _uid = user.uid;
      _password = data['password'];
      _genres = genres;
      _genre = _genres[0];
      _discussionTimeMinutes = setting['discussionTimeMinutesDefault'];
    });

    final Map<String, dynamic> roomData = {
      'genreId': _genre['genreId'],
      'genreName': _genre['genreName'],
      'discussionTimeMinutes': _discussionTimeMinutes
    };

    await FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .update(roomData);
  }

  void activateMonitoringMembers() {
    _membersStreamSubscription = FirebaseFirestore.instance
        .collection(roomsString)
        .doc(_roomId)
        .collection(membersString)
        .snapshots()
        .listen((event) async {
      setState(() {
        _memberRecords = event.docs.map((snapshot) {
          return Record.fromSnapshot(snapshot);
        }).toList();
      });
    });
  }

  void deactivateMonitoringMembers() {
    if (_membersStreamSubscription != null) {
      _membersStreamSubscription.cancel();
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
        if (!snapshot.hasData) {
          return LinearProgressIndicator();
        }
        return _buildList(context, snapshot.data.docs);
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
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          Icons.check_box,
          color: Colors.blue,
        ),
        title: Text(record.name, style: biggerNormalFont),
      ),
    );
  }

  Future<List<Map<String, String>>> getGenreList() async {
    QuerySnapshot genreSnapshot =
        await FirebaseFirestore.instance.collection(genresString).get();
    final genres = genreSnapshot.docs.map((snapshot) {
      final data = snapshot.data();
      final String genreId = data['genreId'];
      final String genreName = data['genreName'];

      return {'genreId': genreId, 'genreName': genreName};
    }).toList();
    return genres;
  }

  Future<Map<String, dynamic>> getRandomThemeInfo(String genreId) async {
    QuerySnapshot themesSnapshot = await FirebaseFirestore.instance
        .collection(genresString)
        .doc(genreId)
        .collection(themesString)
        .get();

    final random = math.Random();

    QueryDocumentSnapshot documentSnapshot =
        themesSnapshot.docs[random.nextInt(themesSnapshot.docs.length)];
    final themeData = documentSnapshot.data();

    Map<String, dynamic> themeInfo = {
      'genreId': genreId,
      'themesId': themeData['themesId']
    };

    return themeInfo;
  }
}
