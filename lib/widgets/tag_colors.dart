import 'package:flutter/material.dart';

class TagColors {
  static const List<Map<String, Color>> _palette = [
    {'bg': Color(0xFFE3F2FD), 'fg': Color(0xFF1976D2)},
    {'bg': Color(0xFFE8F5E9), 'fg': Color(0xFF388E3C)},
    {'bg': Color(0xFFFFF3E0), 'fg': Color(0xFFF57C00)},
    {'bg': Color(0xFFF3E5F5), 'fg': Color(0xFF7B1FA2)},
    {'bg': Color(0xFFFFEBEE), 'fg': Color(0xFFD32F2F)},
    {'bg': Color(0xFFE0F2F1), 'fg': Color(0xFF00796B)},
  ];

  static Map<String, Color> get(String tagName) {
    final hash = tagName.hashCode.abs();
    return _palette[hash % _palette.length];
  }
}
