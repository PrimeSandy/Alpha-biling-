class BillItem {
  final String id;
  String name;
  double unitPrice;
  int quantity;
  bool isTax;
  bool isDiscount;

  BillItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
  })  : isTax = _detectTax(name),
        isDiscount = unitPrice < 0;

  double get price => unitPrice * quantity;

  static bool _detectTax(String name) {
    final lower = name.toLowerCase();
    return [
      'gst',
      'cgst',
      'sgst',
      'vat',
      'service charge',
      'service tax',
      'cess',
      'tax'
    ].any((k) => lower.contains(k));
  }
}
