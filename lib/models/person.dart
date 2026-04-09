import 'package:flutter/material.dart';

class Person {
  final String id;
  final String name;
  final Color avatarColor;
  final Color textColor;
  String upiId;

  Person({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.textColor,
    this.upiId = '',
  });

  String get initials => name
      .trim()
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
      .take(2)
      .join();
}
