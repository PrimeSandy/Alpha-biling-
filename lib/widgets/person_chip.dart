import 'package:flutter/material.dart';

import '../models/person.dart';

class PersonChip extends StatelessWidget {
  const PersonChip({
    super.key,
    required this.person,
    this.selected = false,
    this.onTap,
    this.onDelete,
  });

  final Person person;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      selected: selected,
      onSelected: (_) => onTap?.call(),
      onDeleted: onDelete,
      avatar: CircleAvatar(
        backgroundColor: person.avatarColor,
        child: Text(
          person.initials,
          style: TextStyle(color: person.textColor, fontWeight: FontWeight.w700),
        ),
      ),
      label: Text(person.name),
    );
  }
}
