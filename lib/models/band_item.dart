class BandItem {
  final String name;
  final String detail;
  final String mode;
  final double qty;
  final double price;
  final double total;

  BandItem({
    required this.name,
    required this.detail,
    required this.mode,
    required this.qty,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'detail': detail,
    'mode': mode,
    'qty': qty,
    'price': price,
    'total': total,
  };

  factory BandItem.fromJson(Map<String, dynamic> json) => BandItem(
    name: json['name'],
    detail: json['detail'],
    mode: json['mode'],
    qty: (json['qty'] as num).toDouble(),
    price: (json['price'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
  );
}
