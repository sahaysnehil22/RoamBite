import 'package:flutter/material.dart';
import '../models/food_truck.dart';

class MenuEditorScreen extends StatefulWidget {
  const MenuEditorScreen({super.key});

  @override
  State<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends State<MenuEditorScreen> {
  int _menuVersion = 1;
  final List<MenuItem> _items = [
    const MenuItem(
      id: 'm1',
      name: 'Crispy Quesabirria Tacos (3x)',
      description: 'Braised beef birria, melted Oaxaca cheese, cilantro, onions with rich consomé.',
      price: 13.50,
      imageUrl: 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
      isSignature: true,
    ),
    const MenuItem(
      id: 'm2',
      name: 'Al Pastor Street Tacos',
      description: 'Marinated pork shaved fresh with pineapple and salsa verde.',
      price: 10.99,
      imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
      isSignature: false,
    ),
    const MenuItem(
      id: 'm3',
      name: 'Chorizo Loaded Queso Fries',
      description: 'Golden seasoned waffle fries topped with warm queso blanco and spiced chorizo.',
      price: 9.75,
      imageUrl: 'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80',
      isSignature: true,
    ),
  ];

  void _addNewItem() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    bool isSig = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Dish Name')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (\$)')),
              CheckboxListTile(
                title: const Text('Signature Dish'),
                value: isSig,
                onChanged: (v) => setDlgState(() => isSig = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _menuVersion++;
                    _items.add(MenuItem(
                      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text,
                      description: descCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? 9.99,
                      imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
                      isSignature: isSig,
                    ));
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item added! Menu updated to v$_menuVersion')),
                  );
                }
              },
              child: const Text('Save Item'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu & Pricing Editor'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'v$_menuVersion',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: item.isSignature ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.dividerColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 40),
                ),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (item.isSignature)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: const Text('⭐ Best Dish', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.hintColor, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('\$${item.price.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    _menuVersion++;
                    _items.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dish removed. Menu updated to v$_menuVersion')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
