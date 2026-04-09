import 'package:flutter/material.dart';

import '../models/bill_item.dart';
import '../models/person.dart';

class BillProvider extends ChangeNotifier {
  List<BillItem> items = [];
  List<Person> people = [];
  Map<String, List<String>> assignments = {};
  String? payerId;
  bool taxProportional = true;
  double tip = 0.0;

  void addItem(BillItem item) {
    items.add(item);
    assignments.putIfAbsent(item.id, () => []);
    notifyListeners();
  }

  void updateItemPrice(String itemId, double price) {
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;
    items[idx].unitPrice = price;
    notifyListeners();
  }

  void updateItemQuantity(String itemId, int qty) {
    final idx = items.indexWhere((i) => i.id == itemId);
    if (idx == -1 || qty < 1) return;
    items[idx].quantity = qty;
    notifyListeners();
  }

  void removeItem(String itemId) {
    items.removeWhere((i) => i.id == itemId);
    assignments.remove(itemId);
    notifyListeners();
  }

  void addPerson(Person person) {
    people.add(person);
    notifyListeners();
  }

  void setTip(double val) {
    tip = val;
    notifyListeners();
  }

  void removePerson(String personId) {
    people.removeWhere((p) => p.id == personId);
    for (final entry in assignments.entries) {
      entry.value.remove(personId);
    }
    if (payerId == personId) {
      payerId = null;
    }
    notifyListeners();
  }

  void toggleAssign(String itemId, String personId) {
    final list = assignments.putIfAbsent(itemId, () => []);
    if (list.contains(personId)) {
      list.remove(personId);
    } else {
      list.add(personId);
    }
    notifyListeners();
  }

  void assignAllToItem(String itemId) {
    assignments[itemId] = people.map((p) => p.id).toList();
    notifyListeners();
  }

  void clearItemAssignments(String itemId) {
    assignments[itemId] = [];
    notifyListeners();
  }

  void splitAllEqually() {
    final allIds = people.map((p) => p.id).toList();
    for (final item in items) {
      assignments[item.id] = List<String>.from(allIds);
    }
    notifyListeners();
  }

  void clearAllAssignments() {
    for (final item in items) {
      assignments[item.id] = [];
    }
    notifyListeners();
  }

  void setTaxMode(bool proportional) {
    taxProportional = proportional;
    notifyListeners();
  }

  void setPayer(String? id) {
    payerId = id;
    notifyListeners();
  }

  void updatePersonName(String personId, String name) {
    final idx = people.indexWhere((p) => p.id == personId);
    if (idx == -1) return;
    people[idx] = Person(
      id: people[idx].id,
      name: name,
      avatarColor: people[idx].avatarColor,
      textColor: people[idx].textColor,
      upiId: people[idx].upiId,
    );
    notifyListeners();
  }

  void updatePersonUpi(String personId, String upi) {
    final idx = people.indexWhere((p) => p.id == personId);
    if (idx == -1) return;
    people[idx].upiId = upi;
    notifyListeners();
  }

  bool get hasUnassignedItems =>
      items.any((item) => (assignments[item.id] ?? []).isEmpty);

  double get subtotal => items
      .where((i) => !i.isTax && !i.isDiscount)
      .fold(0.0, (sum, i) => sum + i.price);

  double get totalDiscounts =>
      items.where((i) => i.isDiscount).fold(0.0, (sum, i) => sum + i.price);

  double get totalTax =>
      items.where((i) => i.isTax).fold(0.0, (sum, i) => sum + i.price);

  double get grandTotal => subtotal + totalDiscounts + totalTax + tip;

  Map<String, double> calculateTotals() {
    final totals = {for (var p in people) p.id: 0.0};
    final foodTotals = {for (var p in people) p.id: 0.0};

    // 1. Calculate Base Food/Items
    for (final item in items.where((i) => !i.isTax && !i.isDiscount)) {
      final assigned = assignments[item.id] ?? [];
      if (assigned.isEmpty) continue;
      final share = item.price / assigned.length;
      for (final pid in assigned) {
        totals[pid] = (totals[pid] ?? 0.0) + share;
        foodTotals[pid] = (foodTotals[pid] ?? 0.0) + share;
      }
    }

    // 2. Handle Discounts (Distribute proportionally to food consumed by assigned people)
    for (final item in items.where((i) => i.isDiscount)) {
      final assigned = assignments[item.id] ?? [];
      final groupFoodTotal = assigned.fold(0.0, (sum, pid) => sum + (foodTotals[pid] ?? 0));
      
      if (groupFoodTotal > 0) {
        for (final pid in assigned) {
          final ratio = (foodTotals[pid] ?? 0) / groupFoodTotal;
          totals[pid] = (totals[pid] ?? 0.0) + (item.price * ratio);
        }
      } else if (assigned.isNotEmpty) {
        final share = item.price / assigned.length;
        for (final pid in assigned) {
          totals[pid] = (totals[pid] ?? 0.0) + share;
        }
      }
    }

    // 3. Handle Taxes
    for (final item in items.where((i) => i.isTax)) {
      final assigned = assignments[item.id] ?? [];
      if (assigned.isEmpty) continue;

      if (taxProportional) {
        final groupFoodTotal = assigned.fold(0.0, (sum, pid) => sum + (foodTotals[pid] ?? 0));
        if (groupFoodTotal > 0) {
          for (final pid in assigned) {
            final ratio = (foodTotals[pid] ?? 0) / groupFoodTotal;
            totals[pid] = (totals[pid] ?? 0.0) + (item.price * ratio);
          }
        } else {
          final share = item.price / assigned.length;
          for (final pid in assigned) {
            totals[pid] = (totals[pid] ?? 0.0) + share;
          }
        }
      } else {
        final share = item.price / assigned.length;
        for (final pid in assigned) {
          totals[pid] = (totals[pid] ?? 0.0) + share;
        }
      }
    }

    // 4. Handle Tip (Proportional to final amounts so far)
    final currentTotal = totals.values.fold(0.0, (a, b) => a + b);
    if (tip > 0 && currentTotal > 0) {
      for (final p in people) {
        final ratio = (totals[p.id] ?? 0) / currentTotal;
        totals[p.id] = (totals[p.id] ?? 0.0) + (tip * ratio);
      }
    }

    return totals;
  }

  String buildWhatsappSummary() {
    final totals = calculateTotals();
    final date = DateTime.now();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final payer = payerId != null ? people.firstWhere((p) => p.id == payerId) : null;

    final buffer = StringBuffer();
    buffer.writeln('🧾 *Bill Split — $day/$month/$year*');
    buffer.writeln('──────────────────');

    for (final person in people) {
      final pTotal = totals[person.id] ?? 0.0;
      if (pTotal <= 0) continue;

      buffer.writeln('👤 *${person.name}*');
      
      // List items for this person
      for (final item in items) {
        final assigned = assignments[item.id] ?? [];
        if (assigned.contains(person.id)) {
          final share = item.price / assigned.length;
          final prefix = item.isTax ? '📑' : (item.isDiscount ? '📉' : '🍱');
          buffer.writeln('  $prefix ${item.name}: ₹${share.toStringAsFixed(2)}');
        }
      }
      if (tip > 0) {
        final currentTotal = totals.values.fold(0.0, (a, b) => a + b);
        final ratio = (pTotal / (currentTotal > 0 ? currentTotal : 1));
        buffer.writeln('  ✨ Tip: ₹${(tip * ratio).toStringAsFixed(2)}');
      }
      buffer.writeln('  *Total: ₹${pTotal.toStringAsFixed(2)}*');
      buffer.writeln('');
    }

    buffer.writeln('──────────────────');
    buffer.writeln('💰 *Grand Total: ₹${grandTotal.toStringAsFixed(2)}*');
    
    if (payer != null) {
      buffer.writeln('\n💳 *Paid by:* ${payer.name}');
      if (payer.upiId.isNotEmpty) {
        buffer.writeln('📍 *UPI:* ${payer.upiId}');
      }
    }
    
    buffer.writeln('\n_Shared via BillSplit ✦_');
    return buffer.toString();
  }

  void resetAll() {
    items = [];
    people = [];
    assignments = {};
    payerId = null;
    taxProportional = true;
    tip = 0.0;
    notifyListeners();
  }
}
