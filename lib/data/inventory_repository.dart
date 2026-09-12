import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class InventoryRepository {
  static const _productsKey = 'stockflow.products';
  static const _ordersKey = 'stockflow.orders';

  Future<({List<Product> products, List<StockOrder> orders})> load() async {
    final preferences = await SharedPreferences.getInstance();
    final productJson = preferences.getString(_productsKey);
    final orderJson = preferences.getString(_ordersKey);

    final products = productJson == null
        ? seedProducts
        : (jsonDecode(productJson) as List<dynamic>)
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();
    final orders = orderJson == null
        ? <StockOrder>[]
        : (jsonDecode(orderJson) as List<dynamic>)
              .map((item) => StockOrder.fromJson(item as Map<String, dynamic>))
              .toList();

    return (products: products, orders: orders);
  }

  Future<void> save(List<Product> products, List<StockOrder> orders) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(
        _productsKey,
        jsonEncode(products.map((item) => item.toJson()).toList()),
      ),
      preferences.setString(
        _ordersKey,
        jsonEncode(orders.map((item) => item.toJson()).toList()),
      ),
    ]);
  }

  static const seedProducts = <Product>[
    Product(
      id: 'prd-001',
      name: 'Thermal Receipt Roll',
      sku: 'POS-THERM-80',
      price: 42,
      stock: 36,
      reorderLevel: 12,
    ),
    Product(
      id: 'prd-002',
      name: 'Wireless Barcode Scanner',
      sku: 'POS-SCAN-W1',
      price: 2499,
      stock: 8,
      reorderLevel: 5,
    ),
    Product(
      id: 'prd-003',
      name: 'Portable Label Printer',
      sku: 'INV-LBL-P2',
      price: 4199,
      stock: 4,
      reorderLevel: 5,
    ),
    Product(
      id: 'prd-004',
      name: 'Delivery Pouch',
      sku: 'LOG-POUCH-XL',
      price: 699,
      stock: 18,
      reorderLevel: 8,
    ),
    Product(
      id: 'prd-005',
      name: 'NFC Counter Tag',
      sku: 'POS-NFC-01',
      price: 129,
      stock: 2,
      reorderLevel: 10,
    ),
  ];
}
