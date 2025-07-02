// lib/models/achievement.dart
import 'package:flutter/material.dart';            // ⬅️  add this line
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Achievement {
  final String id;
  final String title;
  final IconData? icon;      // nullable lets you omit an icon if you want

  const Achievement(this.id, this.title, [this.icon]);
}

