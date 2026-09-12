class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.reorderLevel,
  });

  final String id;
  final String name;
  final String sku;
  final double price;
  final int stock;
  final int reorderLevel;

  bool get isLowStock => stock <= reorderLevel;

  Product copyWith({int? stock}) => Product(
    id: id,
    name: name,
    sku: sku,
    price: price,
    stock: stock ?? this.stock,
    reorderLevel: reorderLevel,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'price': price,
    'stock': stock,
    'reorderLevel': reorderLevel,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    sku: json['sku'] as String,
    price: (json['price'] as num).toDouble(),
    stock: json['stock'] as int,
    reorderLevel: json['reorderLevel'] as int,
  );
}

class StockOrder {
  const StockOrder({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double total;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StockOrder.fromJson(Map<String, dynamic> json) => StockOrder(
    id: json['id'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    quantity: json['quantity'] as int,
    total: (json['total'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class InventoryState {
  const InventoryState({
    required this.products,
    required this.orders,
    required this.isLoaded,
  });

  final List<Product> products;
  final List<StockOrder> orders;
  final bool isLoaded;

  int get totalUnits => products.fold(0, (sum, item) => sum + item.stock);
  int get lowStockCount => products.where((item) => item.isLowStock).length;
  double get inventoryValue =>
      products.fold(0, (sum, item) => sum + item.price * item.stock);
  double get salesTotal => orders.fold(0, (sum, item) => sum + item.total);

  InventoryState copyWith({
    List<Product>? products,
    List<StockOrder>? orders,
    bool? isLoaded,
  }) => InventoryState(
    products: products ?? this.products,
    orders: orders ?? this.orders,
    isLoaded: isLoaded ?? this.isLoaded,
  );
}
