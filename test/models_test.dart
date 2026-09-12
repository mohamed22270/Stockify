import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow_flutter/domain/models.dart';

void main() {
  const product = Product(
    id: 'prd-test',
    name: 'Test Product',
    sku: 'TEST-001',
    price: 100,
    stock: 4,
    reorderLevel: 5,
  );

  test('product reports low stock and supports immutable updates', () {
    expect(product.isLowStock, isTrue);

    final replenished = product.copyWith(stock: 12);

    expect(replenished.stock, 12);
    expect(replenished.isLowStock, isFalse);
    expect(product.stock, 4);
  });

  test('inventory metrics are calculated from products and orders', () {
    final order = StockOrder(
      id: 'ORD-1',
      productId: product.id,
      productName: product.name,
      quantity: 2,
      total: 200,
      createdAt: DateTime(2026, 9, 12),
    );
    final state = InventoryState(
      products: [product],
      orders: [order],
      isLoaded: true,
    );

    expect(state.totalUnits, 4);
    expect(state.lowStockCount, 1);
    expect(state.inventoryValue, 400);
    expect(state.salesTotal, 200);
  });

  test('models survive JSON serialization', () {
    final restoredProduct = Product.fromJson(product.toJson());
    final order = StockOrder(
      id: 'ORD-2',
      productId: product.id,
      productName: product.name,
      quantity: 1,
      total: 100,
      createdAt: DateTime(2026, 9, 12),
    );
    final restoredOrder = StockOrder.fromJson(order.toJson());

    expect(restoredProduct.sku, product.sku);
    expect(restoredProduct.price, product.price);
    expect(restoredOrder.id, order.id);
    expect(restoredOrder.createdAt, order.createdAt);
  });
}
