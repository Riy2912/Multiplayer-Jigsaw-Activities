import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

// 1. INITIAL SETUP
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LobbyScreen(), // We start at the Lobby now, not the Game
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

  // Helper: Generate a random 4-digit Room Code
  String _generateRoomCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Action: Create a new room
  void _createRoom() {
    setState(() => _isLoading = true);
    String newCode = _generateRoomCode();

    // Set initial data for this specific room
    DatabaseReference roomRef = FirebaseDatabase.instance.ref("rooms/$newCode/pieces");

    // Create 4 initial pieces scattered around
    List<Map<String, dynamic>> initialPieces = [
      {'x': 50, 'y': 200, 'color': 0xFFE53935}, // Red
      {'x': 150, 'y': 200, 'color': 0xFF43A047}, // Green
      {'x': 50, 'y': 300, 'color': 0xFF1E88E5}, // Blue
      {'x': 150, 'y': 300, 'color': 0xFFFDD835}, // Yellow
    ];

    roomRef.set(initialPieces).then((_) {
      setState(() => _isLoading = false);
      _enterGame(newCode);
    });
  }

  // Action: Join existing room
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
                      icon: const Icon(Icons.add, color: Colors.white), // Force Icon to White
                      label: const Text(
                        "CREATE NEW ROOM",
                        style: TextStyle(
                          color: Colors.white, // Force Text to White
                          fontWeight: FontWeight.bold, // Make it bold for better visibility
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple, // Purple Background
                        foregroundColor: Colors.white,      // White Text/Icon interaction color
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
// SCREEN 2: THE GAME ROOM (Multiplayer Sync)
// ---------------------------------------------------------
class JigsawGame extends StatefulWidget {
  final String roomCode; // We need to know which room we are in
  const JigsawGame({super.key, required this.roomCode});

  @override
  State<JigsawGame> createState() => _JigsawGameState();
}

class _JigsawGameState extends State<JigsawGame> {
  late DatabaseReference _roomRef;
  List<Map<dynamic, dynamic>> _pieces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Connect ONLY to this specific room's data
    _roomRef = FirebaseDatabase.instance.ref("rooms/${widget.roomCode}/pieces");
    _listenToUpdates();
  }

  void _listenToUpdates() {
    _roomRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as List<dynamic>;
        setState(() {
          _pieces = data.map((e) => e as Map<dynamic, dynamic>).toList();
          _isLoading = false;
        });
      }
    });
  }

  void _updatePiece(int index, double x, double y) {
    _roomRef.child(index.toString()).update({'x': x, 'y': y});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room: ${widget.roomCode}"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Render all pieces
          for (int i = 0; i < _pieces.length; i++)
            Positioned(
              left: double.parse(_pieces[i]['x'].toString()),
              top: double.parse(_pieces[i]['y'].toString()),
              child: DraggablePiece(
                index: i,
                colorValue: _pieces[i]['color'],
                onDragEnd: (newX, newY) => _updatePiece(i, newX, newY),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// WIDGET: INDIVIDUAL PIECE (UI Polish)
// ---------------------------------------------------------
class DraggablePiece extends StatelessWidget {
  final int index;
  final int colorValue;
  final Function(double, double) onDragEnd;

  const DraggablePiece({
    super.key,
    required this.index,
    required this.colorValue,
    required this.onDragEnd
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        // We use relative movement, but we update the parent via state
      },
      child: Draggable(
        feedback: _buildBox(true), // What it looks like while dragging
        childWhenDragging: Opacity(opacity: 0.3, child: _buildBox(false)), // Original spot
        child: _buildBox(false), // Normal look
        onDragEnd: (details) {
          // IMPORTANT: Convert global screen coordinates to local Stack coordinates
          // "details.offset" gives the drop position relative to the screen
          // We subtract the AppBar height (approx 80) to correct it.
          onDragEnd(details.offset.dx, details.offset.dy - 80);
        },
      ),
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