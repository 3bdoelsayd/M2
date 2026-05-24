import 'package:flutter/material.dart';

enum KitchenElementType { 
  none, wall, window, door, column, sink, stove, fridge, cabinet, table, chair, washer, appliance, note, scribble
}

class KitchenComponent {
  final String id;
  Offset position;      // Center for objects, Start point for walls
  Offset? endPosition;  // End point for walls
  KitchenElementType type;
  
  double rotation;      // Radians
  double width;         // Meters
  double height;        // Meters
  double depth;         // Meters (Thickness for walls)
  
  Color color;
  String text; // For notes or labels
  List<Offset>? points; // For freehand scribbles

  KitchenComponent({
    required this.id,
    required this.position,
    this.endPosition,
    required this.type,
    this.rotation = 0,
    this.width = 0.6, 
    this.height = 0.9,
    this.depth = 0.6,
    this.color = Colors.grey,
    this.text = "",
    this.points,
  });

  // Real world length in meters
  double get length {
    if (type == KitchenElementType.wall && endPosition != null) {
      return (position - endPosition!).distance * 0.005; // 200px = 1m -> 1px = 0.005m
    }
    return width;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'px': position.dx, 'py': position.dy,
    'ex': endPosition?.dx, 'ey': endPosition?.dy,
    'type': type.index,
    'rotation': rotation,
    'w': width, 'h': height, 'd': depth,
    'text': text,
  };

  factory KitchenComponent.fromJson(Map<String, dynamic> json) => KitchenComponent(
    id: json['id'],
    position: Offset(json['px'], json['py']),
    endPosition: json['ex'] != null ? Offset(json['ex'], json['ey']) : null,
    type: KitchenElementType.values[json['type']],
    rotation: (json['rotation'] ?? 0).toDouble(),
    width: (json['w'] ?? 0.6).toDouble(),
    height: (json['h'] ?? 0.9).toDouble(),
    depth: (json['d'] ?? 0.6).toDouble(),
    text: json['text'] ?? "",
  );
}
