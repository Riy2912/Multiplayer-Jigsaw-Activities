import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

// 1. MAIN ENTRY POINT
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LobbyScreen(),
  ));
}

// ---------------------------------------------------------
// SCREEN 1: THE LOBBY (Create or Join)
// ---------------------------------------------------------
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  String _generateRoomCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _createRoom() {
    setState(() => _isLoading = true);
    String newCode = _generateRoomCode();

    DatabaseReference roomRef = FirebaseDatabase.instance.ref("rooms/$newCode/pieces");

    // STARTING PIECES: All set to 'isPlaced: false' so they appear in the drawer first
    List<Map<String, dynamic>> initialPieces = [
      {'x': 0, 'y': 0, 'color': 0xFFE53935, 'isPlaced': false}, // Red
      {'x': 0, 'y': 0, 'color': 0xFF43A047, 'isPlaced': false}, // Green
      {'x': 0, 'y': 0, 'color': 0xFF1E88E5, 'isPlaced': false}, // Blue
      {'x': 0, 'y': 0, 'color': 0xFFFDD835, 'isPlaced': false}, // Yellow
    ];

    roomRef.set(initialPieces).then((_) {
      setState(() => _isLoading = false);
      _enterGame(newCode);
    });
  }

  void _joinRoom() {
    String code = _codeController.text.trim().toUpperCase();
    if (code.length == 4) {
      _enterGame(code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a 4-letter code")),
      );
    }
  }

  void _enterGame(String roomCode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JigsawGame(roomCode: roomCode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🧩 Jigsaw Party",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)
                  ),
                  const SizedBox(height: 30),

                  // CREATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("CREATE NEW ROOM",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _createRoom,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text("- OR -", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // JOIN INPUT
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "ENTER ROOM CODE",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // JOIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _joinRoom,
                      child: const Text("JOIN ROOM"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// SCREEN 2: THE GAME ROOM (With Drawer)
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
  bool _isLoading = true;
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _roomRef = FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/pieces");
    _listenToUpdates();
  }

  void _listenToUpdates() {
    _roomRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as List<dynamic>;
        setState(() {
          // Convert data and ensure 'isPlaced' defaults to false if missing
          _pieces = data.map((e) {
            final map = e as Map<dynamic, dynamic>;
            map['isPlaced'] = map['isPlaced'] ?? false;
            return map;
          }).toList();
          _isLoading = false;
        });
      }
    });
  }

  // LOGIC: Move piece from Drawer -> Board OR Move piece around Board
  void _updatePiecePosition(int index, Offset globalPosition) {
    // 1. Get the Board's position on the screen
    final RenderBox? renderBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(globalPosition);

    // 2. Update Firebase (This updates everyone's screen)
    _roomRef.child(index.toString()).update({
      'x': localPosition.dx - 40, // Center the piece (80 width / 2)
      'y': localPosition.dy - 40, // Center the piece (80 height / 2)
      'isPlaced': true, // It is now on the board!
    });
  }

  @override
  Widget build(BuildContext context) {
    // Separate pieces into two lists
    final drawerPieces = _pieces.asMap().entries
        .where((entry) => entry.value['isPlaced'] == false)
        .toList();

    final boardPieces = _pieces.asMap().entries
        .where((entry) => entry.value['isPlaced'] == true)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Room: ${widget.roomCode}"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ------------------------------------------
          // TOP AREA: THE BOARD (Drop Zone)
          // ------------------------------------------
          Expanded(
            child: DragTarget<int>(
              key: _boardKey,
              onAcceptWithDetails: (details) {
                _updatePiecePosition(details.data, details.offset);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: Colors.grey[200], // The "Table" color
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Render pieces that are already on the board
                      for (var entry in boardPieces)
                        Positioned(
                          left: double.parse(entry.value['x'].toString()),
                          top: double.parse(entry.value['y'].toString()),
                          child: DraggablePiece(
                            index: entry.key,
                            colorValue: entry.value['color'],
                            onDragEnd: (details) => _updatePiecePosition(entry.key, details.offset),
                          ),
                        ),

                      // Helper text if board is empty
                      if (boardPieces.isEmpty && !_isLoading)
                        const Center(child: Text("Drag pieces here!", style: TextStyle(color: Colors.grey))),
                    ],
                  ),
                );
              },
            ),
          ),

          // ------------------------------------------
          // BOTTOM AREA: THE DRAWER (Scrollable)
          // ------------------------------------------
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF8D6E63), // Brown/Wooden color
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
            ),
            child: drawerPieces.isEmpty
                ? const Center(child: Text("Empty Drawer", style: TextStyle(color: Colors.white)))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              itemCount: drawerPieces.length,
              itemBuilder: (context, listIndex) {
                final originalIndex = drawerPieces[listIndex].key;
                final pieceData = drawerPieces[listIndex].value;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  // We wrap drawer items in Draggable too!
                  child: Draggable<int>(
                    data: originalIndex, // We pass the ID of the piece
                    feedback: Transform.scale(
                      scale: 1.1,
                      child: _buildPieceBox(pieceData['color'], originalIndex, true),
                    ),
                    childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildPieceBox(pieceData['color'], originalIndex, false)
                    ),
                    child: _buildPieceBox(pieceData['color'], originalIndex, false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper to draw the colored box (Used by both Drawer and Board)
  Widget _buildPieceBox(int colorValue, int index, bool isDragging) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Color(colorValue),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: isDragging
            ? [const BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)]
            : [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
      ),
      child: Center(
        child: Text(
          "${index + 1}",
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// WIDGET: DRAGGABLE PIECE (For the Board)
// ---------------------------------------------------------
class DraggablePiece extends StatelessWidget {
  final int index;
  final int colorValue;
  final Function(DraggableDetails) onDragEnd;

  const DraggablePiece({
    super.key,
    required this.index,
    required this.colorValue,
    required this.onDragEnd
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<int>(
      data: index,
      feedback: _buildBox(true),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildBox(false)),
      onDragEnd: onDragEnd,
      child: _buildBox(false),
    );
  }

  Widget _buildBox(bool isDragging) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Color(colorValue),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDragging
            ? [const BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)]
            : [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          "${index + 1}",
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}