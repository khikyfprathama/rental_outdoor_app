import 'item.dart';

class Rental {
  int? id;
  String customerName;
  DateTime startDate;
  DateTime endDate;
  double totalPrice;
  int status; // 0 = Active, 1 = Finished, 2 = Cancelled
  DateTime createdAt;
  List<Item> items;

  Rental({
    this.id,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Rental.fromMap(Map<String, dynamic> map, {List<Item> items = const []}) {
    return Rental(
      id: map['id'],
      customerName: map['customerName'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      totalPrice: map['totalPrice'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      items: items,
    );
  }
}
