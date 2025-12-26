import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LobbyScreen(),
  ));
}

// ---------------------------------------------------------
// SCREEN 1: THE LOBBY (Mode Selection)
// ---------------------------------------------------------
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  final List<String> numberLabels = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"];
  final List<String> fruitLabels = ["Apple", "Banana", "Strawberry", "Pineapple", "Cantaloupe", "Pomegranate", "Custard Apple", "Kiwi", "Grapefruit"];
  final List<String> fruitIcons = ["🍎", "🍌", "🍓", "🍍", "🍈", "🍎", "🍏", "🥝", "🍊"];

  void _createRoom(String mode) {
    setState(() => _isLoading = true);
    String newCode = List.generate(4, (_) => String.fromCharCode(Random().nextInt(26) + 65)).join();

    DatabaseReference roomRef = FirebaseDatabase.instance.ref("rooms/$newCode");

    List<String> labels = mode == "Numbers" ? numberLabels : fruitLabels;
    List<String> hints = mode == "Numbers" ? List.generate(9, (i) => "${i + 1}") : fruitIcons;

    List<Map<String, dynamic>> pieces = List.generate(9, (i) => {
      'x': 0.0,
      'y': 0.0,
      'color': (Colors.primaries[i % Colors.primaries.length]).value,
      'label': labels[i],
      'hint': hints[i],
      'isPlaced': false,
      'isLocked': false,
    });

    roomRef.set({'pieces': pieces, 'mode': mode}).then((_) {
      setState(() => _isLoading = false);
      _enterGame(newCode);
    });
  }

  void _enterGame(String roomCode) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => JigsawGame(roomCode: roomCode)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🧩 Jigsaw Party", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            const Text("Select Mode to Create:"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => _createRoom("Numbers"), child: const Text("Numbers")),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: () => _createRoom("Fruits"), child: const Text("Fruits")),
              ],
            ),
            const Divider(height: 50, indent: 50, endIndent: 50),
            SizedBox(
              width: 200,
              child: TextField(controller: _codeController, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "Enter Room Code")),
            ),
            ElevatedButton(onPressed: () => _enterGame(_codeController.text.toUpperCase()), child: const Text("JOIN")),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// SCREEN 2: THE GAME ROOM
// ---------------------------------------------------------
class JigsawGame extends StatefulWidget {
  final String roomCode;
  const JigsawGame({super.key, required this.roomCode});
  @override
  State<JigsawGame> createState() => _JigsawGameState();
}

class _JigsawGameState extends State<JigsawGame> {
  late DatabaseReference _roomRef;
  List<Map<dynamic, dynamic>> _pieces = [];
  final GlobalKey _boardKey = GlobalKey();
  static const double boardSize = 300.0;
  static const double slotSize = 100.0;

  @override
  void initState() {
    super.initState();
    _roomRef = FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/pieces");
    _roomRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as List<dynamic>;
        setState(() {
          _pieces = data.map((e) => e as Map<dynamic, dynamic>).toList();
        });
      }
    });
  }

  void _updatePiecePosition(int index, Offset globalPosition) {
    // 1. Check if piece is already locked
    if (_pieces[index]['isLocked'] == true) return;

    final RenderBox? renderBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPosition = renderBox.globalToLocal(globalPosition);

    // Use center for snatch detection
    double centerX = localPosition.dx + (slotSize / 2);
    double centerY = localPosition.dy + (slotSize / 2);

    if (centerX >= 0 && centerX < boardSize && centerY >= 0 && centerY < boardSize) {
      int col = (centerX / slotSize).floor().clamp(0, 2);
      int row = (centerY / slotSize).floor().clamp(0, 2);

      double snappedX = col * slotSize;
      double snappedY = row * slotSize;

      // Check if this is the CORRECT slot (Win logic per piece)
      double correctX = (index % 3) * slotSize;
      double correctY = (index ~/ 3) * slotSize;
      bool isCorrect = (snappedX == correctX && snappedY == correctY);

      _roomRef.child(index.toString()).update({
        'x': snappedX,
        'y': snappedY,
        'isPlaced': true,
        'isLocked': isCorrect, // LOCK PIECE IF CORRECT
      });
    } else {
      _roomRef.child(index.toString()).update({'isPlaced': false, 'isLocked': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerPieces = _pieces.asMap().entries.where((e) => !e.value['isPlaced']).toList();
    final boardPieces = _pieces.asMap().entries.where((e) => e.value['isPlaced']).toList();
    bool gameWon = _pieces.isNotEmpty && _pieces.every((p) => p['isLocked'] == true);

    return Scaffold(
      appBar: AppBar(title: Text("Room: ${widget.roomCode}")),
      body: Column(
        children: [
          if (gameWon) Container(width: double.infinity, color: Colors.green, padding: const EdgeInsets.all(10), child: const Text("🏆 PERFECT!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
            child: Center(
              child: DragTarget<int>(
                key: _boardKey,
                onAcceptWithDetails: (details) => _updatePiecePosition(details.data, details.offset),
                builder: (context, _, __) => Container(
                  width: boardSize, height: boardSize,
                  decoration: BoxDecoration(border: Border.all(color: Colors.black45), color: Colors.white),
                  child: Stack(
                    children: [
                      // GRID BACKGROUND (Hints)
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                        itemCount: 9,
                        itemBuilder: (ctx, i) => Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade100)),
                          child: Center(child: Text(_pieces.isNotEmpty ? _pieces[i]['hint'] : "", style: const TextStyle(fontSize: 30, color: Colors.black12))),
                        ),
                      ),
                      // PLACED PIECES
                      for (var entry in boardPieces)
                        Positioned(
                          left: entry.value['x'].toDouble(),
                          top: entry.value['y'].toDouble(),
                          child: DraggablePiece(index: entry.key, data: entry.value, onDragEnd: (d) => _updatePiecePosition(entry.key, d.offset)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 120, color: Colors.brown[400],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: drawerPieces.length,
              itemBuilder: (ctx, i) {
                int idx = drawerPieces[i].key;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DraggablePiece(index: idx, data: drawerPieces[i].value, onDragEnd: (d) => _updatePiecePosition(idx, d.offset)),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class DraggablePiece extends StatelessWidget {
  final int index;
  final Map<dynamic, dynamic> data;
  final Function(DraggableDetails) onDragEnd;
  const DraggablePiece({super.key, required this.index, required this.data, required this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    bool locked = data['isLocked'] ?? false;

    Widget content = Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        color: Color(data['color']),
        borderRadius: BorderRadius.circular(8),
        border: locked ? Border.all(color: Colors.white, width: 3) : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(data['label'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.none)),
            if (locked) const Positioned(bottom: 2, right: 2, child: Icon(Icons.lock, color: Colors.white, size: 14)),
          ],
        ),
      ),
    );

    // If locked, we return the container WITHOUT Draggable
    if (locked) return content;

    return Draggable<int>(
      data: index,
      feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.8, child: content)),
      childWhenDragging: Opacity(opacity: 0.2, child: content),
      onDragEnd: onDragEnd,
      child: content,
    );
  }
}