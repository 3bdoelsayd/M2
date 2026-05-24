import 'band_item.dart';
import 'kitchen_design.dart';

class CustomerRecord {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String address;
  final double paidAmount;
  final String notes;
  final DateTime date;
  final List<BandItem> items;
  final List<KitchenComponent>? designComponents; // حقل جديد لحفظ الرسمة

  CustomerRecord({
    required this.id,
    required this.customerName,
    this.phoneNumber = '',
    this.address = '',
    this.paidAmount = 0,
    this.notes = '',
    required this.date,
    required this.items,
    this.designComponents,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  double get remainingAmount => totalAmount - paidAmount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'phoneNumber': phoneNumber,
    'address': address,
    'paidAmount': paidAmount,
    'notes': notes,
    'date': date.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'designComponents': designComponents?.map((e) => e.toJson()).toList(),
  };

  factory CustomerRecord.fromJson(Map<String, dynamic> json) => CustomerRecord(
    id: json['id'],
    customerName: json['customerName'],
    phoneNumber: json['phoneNumber'] ?? '',
    address: json['address'] ?? '',
    paidAmount: (json['paidAmount'] ?? 0).toDouble(),
    notes: json['notes'] ?? '',
    date: DateTime.parse(json['date']),
    items: json['items'] != null 
        ? (json['items'] as List).map((e) => BandItem.fromJson(e)).toList()
        : [],
    designComponents: json['designComponents'] != null
        ? (json['designComponents'] as List).map((e) => KitchenComponent.fromJson(e)).toList()
        : null,
  );
}
