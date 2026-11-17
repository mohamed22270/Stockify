import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/inventory_controller.dart';
import '../domain/models.dart';

typedef Translator = String Function(String english, String arabic);

const Color brandDark = Color(0xFF102A43);
const Color brandPrimary = Color(0xFF0D9488);
const Color brandAccent = Color(0xFF38BDF8);

class StockFlowShell extends ConsumerStatefulWidget {
  const StockFlowShell({
    super.key,
    required this.arabic,
    required this.darkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final bool arabic;
  final bool darkMode;
  final VoidCallback onLanguageChanged;
  final VoidCallback onThemeChanged;

  @override
  ConsumerState<StockFlowShell> createState() => _StockFlowShellState();
}

class _StockFlowShellState extends ConsumerState<StockFlowShell> {
  int _selectedIndex = 0;
  String _query = '';

  String tr(String english, String arabic) => widget.arabic ? arabic : english;

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 850;

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.space_dashboard_outlined),
        selectedIcon: const Icon(Icons.space_dashboard_rounded),
        label: tr('Dashboard', 'لوحة التحكم'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2_rounded),
        label: tr('Inventory', 'المخزون'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long_rounded),
        label: tr('Orders', 'الطلبات'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.info_outline_rounded),
        selectedIcon: const Icon(Icons.info_rounded),
        label: tr('About', 'عن التطبيق'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [brandPrimary, brandAccent],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Stockify',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: widget.onLanguageChanged,
            icon: const Icon(Icons.translate_rounded),
            label: Text(widget.arabic ? 'EN' : 'العربية'),
          ),
          IconButton(
            tooltip: tr('Toggle theme', 'تغيير المظهر'),
            onPressed: widget.onThemeChanged,
            icon: Icon(
              widget.darkMode ? Icons.light_mode : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: inventory.isLoaded
          ? Row(
              children: [
                if (wide)
                  AppSidebar(
                    selectedIndex: _selectedIndex,
                    destinations: destinations,
                    tr: tr,
                    onSelected: (value) {
                      setState(() => _selectedIndex = value);
                    },
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      DashboardPage(
                        state: inventory,
                        tr: tr,
                        onViewInventory: () {
                          setState(() => _selectedIndex = 1);
                        },
                      ),
                      InventoryPage(
                        state: inventory,
                        tr: tr,
                        query: _query,
                        onQueryChanged: (value) {
                          setState(() => _query = value);
                        },
                        onReceive: _showReceiveDialog,
                        onSell: _showOrderDialog,
                      ),
                      OrdersPage(state: inventory, tr: tr),
                      AboutPage(tr: tr),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) {
                setState(() => _selectedIndex = value);
              },
              destinations: destinations,
            ),
    );
  }

  Future<void> _showReceiveDialog(Product product) async {
    final quantity = await _quantityDialog(
      title: tr('Receive stock', 'استلام المخزون'),
      action: tr('Add stock', 'إضافة'),
      maximum: 999,
    );

    if (quantity != null && quantity > 0) {
      await ref
          .read(inventoryControllerProvider.notifier)
          .receiveStock(product.id, quantity);
    }
  }

  Future<void> _showOrderDialog(Product product) async {
    final quantity = await _quantityDialog(
      title: tr('Create order', 'إنشاء طلب'),
      action: tr('Confirm order', 'تأكيد الطلب'),
      maximum: product.stock,
    );

    if (quantity == null || quantity <= 0) return;

    final success = await ref
        .read(inventoryControllerProvider.notifier)
        .createOrder(product.id, quantity);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? tr('Order created offline', 'تم إنشاء الطلب دون اتصال')
              : tr('Not enough stock', 'المخزون غير كافٍ'),
        ),
      ),
    );
  }

  Future<int?> _quantityDialog({
    required String title,
    required String action,
    required int maximum,
  }) {
    final controller = TextEditingController(text: '1');

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: tr('Quantity', 'الكمية'),
            helperText: '${tr('Available', 'المتاح')}: $maximum',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, int.tryParse(controller.text));
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.tr,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final Translator tr;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.fromLTRB(16, 8, 0, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A43), Color(0xFF0B1F33)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22071524),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [brandPrimary, brandAccent],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stockify',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        tr('Inventory Management', 'إدارة المخزون'),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            tr('MAIN MENU', 'القائمة الرئيسية'),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(destinations.length, (index) {
            final selected = index == selectedIndex;
            final destination = destinations[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: selected
                    ? brandPrimary.withValues(alpha: .22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? (destination.selectedIcon as Icon).icon
                              : (destination.icon as Icon).icon,
                          color: selected
                              ? const Color(0xFF5EEAD4)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          destination.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFFCBD5E1),
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.circle, size: 7, color: brandAccent),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          const Divider(color: Color(0xFF294158)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: brandPrimary,
                  foregroundColor: Colors.white,
                  child: Text(
                    'MA',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mohamed Abo alfetoah',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Modified by Developer',
                        style: TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Stockify • Portfolio Edition',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .4),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        child,
      ],
    ),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.state,
    required this.tr,
    required this.onViewInventory,
  });

  final InventoryState state;
  final Translator tr;
  final VoidCallback onViewInventory;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        tr('Stock units', 'وحدات المخزون'),
        '${state.totalUnits}',
        Icons.inventory_rounded,
        const Color(0xFF0F766E),
        tr(
          'Across ${state.products.length} products',
          'ضمن ${state.products.length} منتجات',
        ),
      ),
      (
        tr('Inventory value', 'قيمة المخزون'),
        '₹${state.inventoryValue.toStringAsFixed(0)}',
        Icons.currency_rupee_rounded,
        const Color(0xFF2563EB),
        tr('Current stock value', 'قيمة المخزون الحالية'),
      ),
      (
        tr('Low stock', 'مخزون منخفض'),
        '${state.lowStockCount}',
        Icons.warning_amber_rounded,
        const Color(0xFFEA580C),
        tr('Needs your attention', 'يحتاج إلى انتباهك'),
      ),
      (
        tr('Offline sales', 'المبيعات'),
        '₹${state.salesTotal.toStringAsFixed(0)}',
        Icons.trending_up_rounded,
        const Color(0xFF64748B),
        tr(
          '${state.orders.length} local orders',
          '${state.orders.length} طلبات محلية',
        ),
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 1150
        ? 4
        : width > 640
        ? 2
        : 1;

    return PageFrame(
      title: tr('Welcome to Stockify', 'أهلاً بك في Stockify'),
      subtitle: tr(
        'Your inventory overview. Changes are saved offline.',
        'نظرة عامة على مخزونك. يتم حفظ التغييرات دون اتصال.',
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0EA5A4)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Smart Inventory Control', 'إدارة ذكية للمخزون'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tr(
                          'Manage products, stock and orders in one place.',
                          'أدر المنتجات والمخزون والطلبات من مكان واحد.',
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 152,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final metric = metrics[index];

              return MetricCard(
                label: metric.$1,
                value: metric.$2,
                icon: metric.$3,
                accent: metric.$4,
                caption: metric.$5,
              );
            },
          ),
          const SizedBox(height: 20),
          InventoryHealthCard(
            state: state,
            tr: tr,
            onViewInventory: onViewInventory,
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.code_rounded)),
              title: Text(
                tr('Application developer', 'مطور التطبيق'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Mohamed Abo alfetoah'),
              trailing: const Icon(Icons.verified_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String caption;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const Spacer(),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            caption,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

class InventoryHealthCard extends StatelessWidget {
  const InventoryHealthCard({
    super.key,
    required this.state,
    required this.tr,
    required this.onViewInventory,
  });

  final InventoryState state;
  final Translator tr;
  final VoidCallback onViewInventory;

  @override
  Widget build(BuildContext context) {
    final healthy = state.products.length - state.lowStockCount;

    final ratio = state.products.isEmpty
        ? 0.0
        : healthy / state.products.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;

            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tr('Inventory health', 'صحة المخزون'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  tr(
                    '$healthy of ${state.products.length} products have healthy stock levels.',
                    '$healthy من ${state.products.length} منتجات بمستوى مخزون جيد.',
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 9,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(brandPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onViewInventory,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    tr('Review low-stock items', 'مراجعة المخزون المنخفض'),
                  ),
                ),
              ],
            );

            final attention = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Requires attention', 'يتطلب الانتباه'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ...state.products
                    .where((item) => item.isLowStock)
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA580C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${product.stock} ${tr('left', 'متبقي')}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );

            return compact
                ? Column(
                    children: [summary, const SizedBox(height: 24), attention],
                  )
                : Row(
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: 36),
                      Expanded(child: attention),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class InventoryPage extends StatelessWidget {
  const InventoryPage({
    super.key,
    required this.state,
    required this.tr,
    required this.query,
    required this.onQueryChanged,
    required this.onReceive,
    required this.onSell,
  });

  final InventoryState state;
  final Translator tr;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Product> onReceive;
  final ValueChanged<Product> onSell;

  @override
  Widget build(BuildContext context) {
    final products = state.products.where((product) {
      final filter = query.toLowerCase();

      return product.name.toLowerCase().contains(filter) ||
          product.sku.toLowerCase().contains(filter);
    }).toList();

    return PageFrame(
      title: tr('Inventory', 'المخزون'),
      subtitle: tr(
        'Search products, receive stock, and create offline orders.',
        'ابحث عن المنتجات واستلم المخزون وأنشئ الطلبات.',
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr(
                'Search by product or SKU',
                'البحث بالمنتج أو الرمز',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...products.map(
            (product) => LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;

                final details = Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: product.isLowStock
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        product.isLowStock
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${product.sku}  •  ₹${product.price.toStringAsFixed(0)}  •  ${tr('Stock', 'المخزون')}: ${product.stock}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.isLowStock
                                  ? const Color(0xFFFFEDD5)
                                  : const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.stock == 0
                                  ? tr('Out of stock', 'نفد المخزون')
                                  : product.isLowStock
                                  ? tr('Low stock', 'مخزون منخفض')
                                  : tr('Healthy', 'جيد'),
                              style: TextStyle(
                                color: product.isLowStock
                                    ? const Color(0xFF9A3412)
                                    : const Color(0xFF115E59),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actions = Row(
                  mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Flexible(
                      fit: compact ? FlexFit.tight : FlexFit.loose,
                      child: OutlinedButton(
                        onPressed: () => onReceive(product),
                        child: Text(tr('Receive', 'استلام')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: compact ? FlexFit.tight : FlexFit.loose,
                      child: FilledButton(
                        onPressed: product.stock == 0
                            ? null
                            : () => onSell(product),
                        child: Text(tr('Sell', 'بيع')),
                      ),
                    ),
                  ],
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: compact
                          ? Column(
                              children: [
                                details,
                                const SizedBox(height: 16),
                                actions,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: details),
                                const SizedBox(width: 18),
                                actions,
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                tr('No products found.', 'لم يتم العثور على منتجات.'),
              ),
            ),
        ],
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, required this.state, required this.tr});

  final InventoryState state;
  final Translator tr;

  @override
  Widget build(BuildContext context) => PageFrame(
    title: tr('Orders', 'الطلبات'),
    subtitle: tr(
      'Orders created on this device, even while offline.',
      'الطلبات التي تم إنشاؤها على هذا الجهاز دون اتصال.',
    ),
    child: state.orders.isEmpty
        ? Card(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 54,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr('No orders yet', 'لا توجد طلبات بعد'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      'Open Inventory and sell a product to create one.',
                      'افتح المخزون وقم ببيع منتج لإنشاء طلب.',
                    ),
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: state.orders
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.check_rounded),
                        ),
                        title: Text(
                          order.productName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${order.id}  •  ${tr('Qty', 'الكمية')}: ${order.quantity}',
                        ),
                        trailing: Text(
                          '₹${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.tr});

  final Translator tr;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: tr('About Stockify', 'عن Stockify'),
      subtitle: tr(
        'Learn more about the application and its developer.',
        'تعرف على التطبيق والمطور.',
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [brandDark, brandPrimary, brandAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Stockify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Smart Inventory Management', 'إدارة ذكية للمخزون'),
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('About the application', 'عن التطبيق'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'Stockify is an inventory and order management application designed to help users organize products, monitor stock levels, receive inventory, and manage sales in one place.',
                      'Stockify هو تطبيق لإدارة المخزون والطلبات، يساعد المستخدمين على تنظيم المنتجات ومتابعة مستويات المخزون واستلام البضائع وإدارة المبيعات من مكان واحد.',
                    ),
                    style: const TextStyle(height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Main features', 'المميزات الرئيسية'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AboutFeature(
                    icon: Icons.inventory_2_outlined,
                    title: tr('Inventory management', 'إدارة المخزون'),
                    subtitle: tr(
                      'Manage products and stock quantities.',
                      'إدارة المنتجات وكميات المخزون.',
                    ),
                  ),
                  _AboutFeature(
                    icon: Icons.receipt_long_outlined,
                    title: tr('Order management', 'إدارة الطلبات'),
                    subtitle: tr(
                      'Create and track product orders.',
                      'إنشاء ومتابعة طلبات المنتجات.',
                    ),
                  ),
                  _AboutFeature(
                    icon: Icons.wifi_off_rounded,
                    title: tr('Offline support', 'العمل دون إنترنت'),
                    subtitle: tr(
                      'Save your changes locally on your device.',
                      'حفظ التغييرات محلياً على جهازك.',
                    ),
                  ),
                  _AboutFeature(
                    icon: Icons.language_rounded,
                    title: tr('Bilingual interface', 'واجهة بلغتين'),
                    subtitle: tr(
                      'Switch between Arabic and English.',
                      'التبديل بين العربية والإنجليزية.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: brandPrimary,
                    child: Text(
                      'MA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr('Developer', 'المطور'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Mohamed Abo alfetoah',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'Customized by Mohamed Abo alfetoah',
                      'تم تخصيص هذه النسخة بواسطة Mohamed Abo alfetoah',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Stockify • Portfolio Edition',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: brandPrimary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: brandPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
