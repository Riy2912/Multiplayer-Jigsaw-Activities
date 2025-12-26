import 'package:flutter/material.dart';

class PieceWidget extends StatelessWidget {
  final Map data;
  final bool isMine;
  final Function(DraggableDetails) onDragEnd;

  const PieceWidget({super.key, required this.data, required this.isMine, required this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    bool locked = data['isLocked'] ?? false;
    Color pieceColor = Color(data['color']);
    // Player's border color
    Color playerColor = Color(data['uColor'] ?? 0xFFFFFFFF);

    Widget content = Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        color: pieceColor,
        // The border indicates who is currently holding/moving the piece
        border: Border.all(
          color: isMine && !locked ? playerColor : Colors.white.withOpacity(0.4),
          width: isMine ? 5 : 1,
        ),
        boxShadow: isMine ? [BoxShadow(color: playerColor.withOpacity(0.5), blurRadius: 10)] : null,
      ),
      child: Stack(children: [
        Center(child: Text(data['label'],
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, decoration: TextDecoration.none))),
        if (data['uAvatar'] != null && !locked)
          Positioned(top: 4, right: 4, child: Image.network(data['uAvatar'], width: 22)),
      ]),
    );

    if (locked || !isMine) return content;
    return Draggable<int>(
      data: data['index'],
      feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.8, child: content)),
      childWhenDragging: Container(width: 100, height: 100, color: Colors.black12),
      onDragEnd: onDragEnd,
      child: content,
    );
  }
}