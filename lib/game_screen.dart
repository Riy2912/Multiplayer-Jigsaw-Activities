import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:confetti/confetti.dart';
import 'piece_widget.dart';

class GameScreen extends StatefulWidget {
  final String roomCode, uAvatar;
  final int uColor;
  const GameScreen({super.key, required this.roomCode, required this.uAvatar, required this.uColor});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DatabaseReference _ref;
  List<dynamic> _pieces = [];
  final String _myId = Random().nextInt(99999).toString();
  final GlobalKey _boardKey = GlobalKey();
  late ConfettiController _conf;
  int _timer = 0, _shuffle = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _conf = ConfettiController(duration: const Duration(seconds: 5));
    _ref = FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/pieces");

    // 1. Register Player Presence
    FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/players/$_myId").set({
      'uAvatar': widget.uAvatar, 'uColor': widget.uColor
    });
    // Cleanup if app closes
    FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/players/$_myId").onDisconnect().remove();

    _ref.onValue.listen((e) {
      if (!mounted) return;
      setState(() => _pieces = e.snapshot.value as List? ?? []);
      if (_pieces.isNotEmpty && _pieces.every((p) => p['isLocked'] == true)) _conf.play();
    });

    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timer > 0) setState(() => _timer--);
      if (_timer == 0 && _pieces.any((p) => p['assignedTo'] == _myId)) _pass();
    });
  }

  void _grab() {
    var avail = [for (int i=0; i<_pieces.length; i++) if (!_pieces[i]['isPlaced'] && _pieces[i]['assignedTo'] == null && !_pieces[i]['isLocked']) i];
    if (avail.isEmpty) return;
    _ref.child(avail[Random().nextInt(avail.length)].toString()).update({
      'assignedTo': _myId, 'uAvatar': widget.uAvatar, 'uColor': widget.uColor
    });
    setState(() { _timer = 30; _shuffle++; });
  }

  void _pass() {
    for (int i=0; i<_pieces.length; i++) if (_pieces[i]['assignedTo'] == _myId) {
      _ref.child(i.toString()).update({'assignedTo': null, 'uAvatar': null, 'uColor': null});
    }
    _grab();
  }

  void _move(int i, Offset pos) {
    final RenderBox? b = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (b == null) return;
    Offset local = b.globalToLocal(pos);
    int col = ((local.dx + 50) / 100).floor().clamp(0, 2), row = ((local.dy + 50) / 100).floor().clamp(0, 2);
    bool correct = (col == i % 3 && row == i ~/ 3);
    _ref.child(i.toString()).update({
      'x': col * 100.0, 'y': row * 100.0, 'isPlaced': true, 'isLocked': correct, 'assignedTo': correct ? "LOCKED" : _myId
    });
    if (correct) _grab();
  }

  @override
  Widget build(BuildContext context) {
    int myP = _pieces.indexWhere((p) => p['assignedTo'] == _myId);
    bool win = _pieces.isNotEmpty && _pieces.every((p) => p['isLocked'] == true);

    return Scaffold(
      appBar: AppBar(title: Text("ROOM: ${widget.roomCode}"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: Stack(children: [
        Column(children: [
          ListTile(tileColor: Colors.blueGrey[50], title: Text(myP != -1 ? "Move: ${_pieces[myP]['label']} (${_timer}s)" : "Get Piece"),
              trailing: ElevatedButton(onPressed: myP != -1 ? _pass : _grab, child: Text(myP != -1 ? "PASS" : "START"))),
          Expanded(child: Center(child: Container(key: _boardKey, width: 300, height: 300, child: Stack(children: [
            GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3), itemCount: 9, itemBuilder: (c, i) => Container(
                decoration: BoxDecoration(color: _pieces.isNotEmpty ? Color(_pieces[i]['color']).withOpacity(0.15) : Colors.white, border: Border.all(color: Colors.black12)),
                child: Center(child: Text(_pieces.isNotEmpty ? _pieces[i]['hint'] : "", style: const TextStyle(fontSize: 32, color: Colors.black26))))),
            for (int i = 0; i < _pieces.length; i++) if (_pieces[i]['isPlaced']) Positioned(left: _pieces[i]['x'].toDouble(), top: _pieces[i]['y'].toDouble(), child: PieceWidget(data: _pieces[i], isMine: _pieces[i]['assignedTo'] == _myId, onDragEnd: (d) => _move(i, d.offset))),
          ])))),
          Container(height: 120, color: Colors.brown[700], child: AnimatedSwitcher(duration: const Duration(milliseconds: 500), child: ListView.builder(key: ValueKey(_shuffle), scrollDirection: Axis.horizontal, itemCount: _pieces.length, itemBuilder: (c, i) {
            if (_pieces[i]['isPlaced'] || _pieces[i]['isLocked']) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.all(8.0), child: PieceWidget(data: _pieces[i], isMine: _pieces[i]['assignedTo'] == _myId, onDragEnd: (d) => _move(i, d.offset)));
          }))),
        ]),
        if (win) Container(color: Colors.black.withOpacity(0.85), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("🎉", style: TextStyle(fontSize: 60)),
          const Text("PUZZLE COMPLETED!", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {
            FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/players/$_myId").remove();
            Navigator.pop(context);
          }, child: const Text("PLAY AGAIN"))
        ]))),
        Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _conf, blastDirectionality: BlastDirectionality.explosive)),
      ]),
    );
  }
  @override void dispose() {
    FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/players/$_myId").remove();
    _t?.cancel(); _conf.dispose(); super.dispose();
  }
}