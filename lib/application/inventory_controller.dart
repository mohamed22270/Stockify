import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/inventory_repository.dart';
import '../domain/models.dart';

final inventoryRepositoryProvider = Provider((ref) => InventoryRepository());

final inventoryControllerProvider =
    NotifierProvider<InventoryController, InventoryState>(
      InventoryController.new,
    );

class InventoryController extends Notifier<InventoryState> {
  InventoryRepository get _repository => ref.read(inventoryRepositoryProvider);

  @override
  InventoryState build() {
    Future<void>.microtask(_hydrate);
    return const InventoryState(products: [], orders: [], isLoaded: false);
  }

  Future<void> _hydrate() async {
    final data = await _repository.load();
    state = InventoryState(
      products: data.products,
      orders: data.orders,
      isLoaded: true,
    );
  }

  Future<void> receiveStock(String productId, int quantity) async {
    if (quantity <= 0) return;
    final products = state.products
        .map(
          (item) => item.id == productId
              ? item.copyWith(stock: item.stock + quantity)
              : item,
        )
        .toList();
    state = state.copyWith(products: products);
    await _repository.save(state.products, state.orders);
  }

  Future<bool> createOrder(String productId, int quantity) async {
    if (quantity <= 0) return false;
    final product = state.products.firstWhere((item) => item.id == productId);
    if (product.stock < quantity) return false;

    final products = state.products
        .map(
          (item) => item.id == productId
              ? item.copyWith(stock: item.stock - quantity)
              : item,
        )
        .toList();
    final order = StockOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      total: product.price * quantity,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      products: products,
      orders: [order, ...state.orders],
    );
    await _repository.save(state.products, state.orders);
    return true;
  }
}
