import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

// 1. MAIN ENTRY POINT
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (connects to your google-services.json)
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: JigsawGame(),
  ));
}

class JigsawGame extends StatefulWidget {
  const JigsawGame({super.key});

  @override
  State<JigsawGame> createState() => _JigsawGameState();
}

class _JigsawGameState extends State<JigsawGame> {
  // Connection to the database path "pieces"
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("pieces");

  // Local list to hold the pieces' positions
  List<Map<dynamic, dynamic>> _pieces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupGameListener();
  }

  // 2. LISTEN TO DATABASE CHANGES
  void _setupGameListener() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        // If data exists in Firebase, update our screen to match it
        final data = event.snapshot.value as List<dynamic>;
        setState(() {
          _pieces = data.map((e) => e as Map<dynamic, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        // If Database is empty (first run), create the puzzle pieces
        _initializeDatabase();
      }
    });
  }

  // 3. CREATE INITIAL PIECES (Run once)
  void _initializeDatabase() {
    List<Map<String, double>> initialPieces = [
      {'x': 50, 'y': 50, 'color': 0xFFFF0000}, // Red Piece
      {'x': 150, 'y': 50, 'color': 0xFF00FF00}, // Green Piece
      {'x': 50, 'y': 150, 'color': 0xFF0000FF}, // Blue Piece
      {'x': 150, 'y': 150, 'color': 0xFFFFFF00}, // Yellow Piece
    ];
    _dbRef.set(initialPieces);
  }

  // 4. UPDATE FIREBASE WHEN DRAGGING
  void _updatePiecePosition(int index, double newX, double newY) {
    // We update ONLY the x and y coordinates in the database
    _dbRef.child(index.toString()).update({
      'x': newX,
      'y': newY,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Multiplayer Jigsaw")),
      body: Stack(
        children: [
          // Build all pieces from the list
          for (int i = 0; i < _pieces.length; i++)
            Positioned(
              left: double.parse(_pieces[i]['x'].toString()),
              top: double.parse(_pieces[i]['y'].toString()),
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Calculate new position
                  double currentX = double.parse(_pieces[i]['x'].toString());
                  double currentY = double.parse(_pieces[i]['y'].toString());

                  // Send new position to Firebase immediately
                  _updatePiecePosition(
                      i,
                      currentX + details.delta.dx,
                      currentY + details.delta.dy
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Color(_pieces[i]['color']),
                      border: Border.all(width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(blurRadius: 5, color: Colors.black26)
                      ]
                  ),
                  child: Center(
                    child: Text(
                      "${i + 1}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}