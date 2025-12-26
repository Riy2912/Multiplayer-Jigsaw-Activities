import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  String selectedAvatar = "";
  int? selectedColorValue;
  List<String> takenAvatars = [];
  List<int> takenColors = [];

  final List<String> avatars = [
    "https://cdn-icons-png.flaticon.com/512/1998/1998592.png", // Fox
    "https://cdn-icons-png.flaticon.com/512/1998/1998661.png", // Koala
    "https://cdn-icons-png.flaticon.com/512/1998/1998765.png", // Panda
    "https://cdn-icons-png.flaticon.com/512/2622/2622075.png", // Flower
    "https://cdn-icons-png.flaticon.com/512/2622/2622112.png", // Leaf
  ];

  final List<Color> colors = [Colors.deepPurple, Colors.red, Colors.green, Colors.orange, Colors.blue, Colors.pink, Colors.teal];

  // Logic to see what others in the room have picked
  void _checkAvailability(String code) async {
    if (code.length != 4) return;
    final snapshot = await FirebaseDatabase.instance.ref("rooms/${code.toUpperCase()}/players").get();
    if (snapshot.exists) {
      Map data = snapshot.value as Map;
      setState(() {
        takenAvatars = data.values.map((p) => p['uAvatar'].toString()).toList();
        takenColors = data.values.map((p) => p['uColor'] as int).toList();
      });
    } else {
      setState(() { takenAvatars = []; takenColors = []; });
    }
  }

  void _createRoom(String mode) {
    if (selectedAvatar.isEmpty || selectedColorValue == null) return;
    String code = List.generate(4, (_) => String.fromCharCode(Random().nextInt(26) + 65)).join();

    List<String> labels = mode == "Numbers"
        ? ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
        : ["Apple", "Banana", "Strawberry", "Pineapple", "Cantaloupe", "Watermelon", "Grape", "Kiwi", "Grapefruit"];
    List<String> hints = mode == "Numbers" ? List.generate(9, (i) => "${i + 1}") : ["🍎", "🍌", "🍓", "🍍", "🍈", "🍉", "🍇", "🥝", "🍊"];

    List<Map<String, dynamic>> pieces = List.generate(9, (i) => {
      'label': labels[i], 'hint': hints[i], 'isPlaced': false, 'isLocked': false,
      'color': Colors.primaries[i % Colors.primaries.length].value, 'x': 0.0, 'y': 0.0, 'assignedTo': null,
    });

    FirebaseDatabase.instance.ref("rooms/$code").set({'pieces': pieces, 'mode': mode});
    _join(code);
  }

  void _join(String code) {
    if (selectedAvatar.isEmpty || selectedColorValue == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(
        roomCode: code.toUpperCase(), uAvatar: selectedAvatar, uColor: selectedColorValue!
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Your Player"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(child: Column(children: [
        const Text("1. Select Avatar", style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(alignment: WrapAlignment.center, children: avatars.map((url) {
          bool isTaken = takenAvatars.contains(url);
          return GestureDetector(
              onTap: isTaken ? null : () => setState(() => selectedAvatar = url),
              child: Opacity(opacity: isTaken ? 0.2 : 1.0, child: Container(margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: selectedAvatar == url ? Colors.blue : Colors.transparent, width: 3), shape: BoxShape.circle),
                  child: CircleAvatar(backgroundImage: NetworkImage(url), radius: 30, backgroundColor: Colors.transparent))));
        }).toList()),
        const SizedBox(height: 20),
        const Text("2. Select Border Color", style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(alignment: WrapAlignment.center, children: colors.map((c) {
          bool isTaken = takenColors.contains(c.value);
          return GestureDetector(
              onTap: isTaken ? null : () => setState(() => selectedColorValue = c.value),
              child: Opacity(opacity: isTaken ? 0.2 : 1.0, child: Container(width: 45, height: 45, margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: selectedColorValue == c.value ? const Icon(Icons.check, color: Colors.white) : null)));
        }).toList()),
        const Divider(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(onPressed: () => _createRoom("Numbers"), child: const Text("New Numbers")),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: () => _createRoom("Fruits"), child: const Text("New Fruits")),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: 220, child: TextField(controller: _codeController, onChanged: _checkAvailability, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "Enter Code to Join", border: OutlineInputBorder()))),
        ElevatedButton(onPressed: () => _join(_codeController.text), child: const Text("JOIN ROOM")),
      ])),
    );
  }
}