import 'package:flutter/material.dart';
import '../models/food_truck.dart';
import '../services/demo_trucks.dart';
import '../services/supabase_service.dart';
import '../widgets/media_picker_sheet.dart';

class MenuEditorScreen extends StatefulWidget {
  final String truckId;

  const MenuEditorScreen({
    super.key,
    this.truckId = 'a1111111-aaaa-1111-aaaa-111111111111',
  });

  @override
  State<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends State<MenuEditorScreen> {
  int _menuVersion = 4;
  late List<MenuItem> _items;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final truck = DemoTrucks.getTruckById(widget.truckId);
    _items = List<MenuItem>.from(truck.menu);
  }

  Future<void> _syncMenuToSupabase() async {
    setState(() => _isSyncing = true);
    await SupabaseService().syncTruckMenuToDb(
      truckId: widget.truckId,
      items: _items,
      menuVersion: _menuVersion,
    );
    if (!mounted) return;
    setState(() => _isSyncing = false);
  }

  Future<void> _openAddOrEditDishSheet({MenuItem? existingDish}) async {
    final isEditing = existingDish != null;
    final nameCtrl = TextEditingController(text: existingDish?.name ?? '');
    final descCtrl =
        TextEditingController(text: existingDish?.description ?? '');
    final priceCtrl = TextEditingController(
      text: existingDish != null ? existingDish.price.toStringAsFixed(2) : '',
    );
    String selectedImageUrl = existingDish?.imageUrl.isNotEmpty == true
        ? existingDish!.imageUrl
        : 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80';
    String imageSourceLabel =
        isEditing ? 'Current Dish Photo' : 'Default Dish Photo';
    bool isSignature = existingDish?.isSignature ?? true;
    bool isVegetarian = existingDish?.isVegetarian ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Dish & Photo'
                              : 'Add Dish with Camera / Gallery Photo',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Dish Photo Preview + Camera / Gallery Picker Button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFF5722)
                                .withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              selectedImageUrl,
                              width: 78,
                              height: 78,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 78,
                                height: 78,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.fastfood),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dish Menu Photo',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  imageSourceLabel,
                                  style: TextStyle(
                                      color: theme.hintColor, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5722),
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () async {
                                    final picked =
                                        await showRoamBiteMediaPicker(
                                      ctx,
                                      title:
                                          'Upload Dish Photo (Camera or Gallery)',
                                      allowVideo: false,
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        selectedImageUrl = picked.url;
                                        imageSourceLabel = picked.sourceLabel;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_a_photo, size: 15),
                                  label: const Text(
                                    'Upload / Camera',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Dish Name',
                        hintText: 'e.g. Birria Ramen Bowl',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ingredients & Description',
                        hintText: 'e.g. Slow-braised beef birria with noodles',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price (USD)',
                        prefixText: r'$ ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Vegetarian Dish (Veg Mode Compatible)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      secondary:
                          const Icon(Icons.eco, color: Color(0xFF00C853)),
                      value: isVegetarian,
                      activeThumbColor: const Color(0xFF00C853),
                      onChanged: (v) =>
                          setModalState(() => isVegetarian = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mark as Bestseller / Signature Dish',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      secondary:
                          const Icon(Icons.star, color: Color(0xFFFF5722)),
                      value: isSignature,
                      activeThumbColor: const Color(0xFFFF5722),
                      onChanged: (v) => setModalState(() => isSignature = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final price =
                              double.tryParse(priceCtrl.text.trim()) ?? 9.99;

                          final dish = MenuItem(
                            id: existingDish?.id ??
                                'dish_${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? 'Freshly prepared to order at our food truck window.'
                                : descCtrl.text.trim(),
                            price: price,
                            imageUrl: selectedImageUrl,
                            isSignature: isSignature,
                            isVegetarian: isVegetarian,
                          );

                          if (isEditing) {
                            DemoTrucks.updateDishInTruck(widget.truckId, dish);
                          } else {
                            DemoTrucks.addDishToTruck(widget.truckId, dish);
                          }

                          setState(() {
                            _items = List<MenuItem>.from(
                                DemoTrucks.getTruckById(widget.truckId).menu);
                            _menuVersion++;
                          });

                          Navigator.pop(ctx);
                          await _syncMenuToSupabase();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF00C853),
                                content: Text(
                                  isEditing
                                      ? 'Updated "${dish.name}" (v$_menuVersion synced)!'
                                      : 'Added "${dish.name}" with photo to live menu (v$_menuVersion)!',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: Icon(isEditing ? Icons.save : Icons.add_task),
                        label: Text(
                          isEditing
                              ? 'Save Dish Changes'
                              : 'Publish Dish to Live Menu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDish(MenuItem dish) async {
    DemoTrucks.deleteDishFromTruck(widget.truckId, dish.id);
    setState(() {
      _items =
          List<MenuItem>.from(DemoTrucks.getTruckById(widget.truckId).menu);
      _menuVersion++;
    });
    await _syncMenuToSupabase();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${dish.name}" from menu (v$_menuVersion).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu & Dish Photo Manager'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isSyncing ? 'SYNCING...' : 'v$_menuVersion LIVE',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddOrEditDishSheet(),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text(
          'Add Dish + Photo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openAddOrEditDishSheet(existingDish: item),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72,
                            height: 72,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood,
                                color: Color(0xFFFF5722)),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.crop_square_sharp,
                            size: 14,
                            color: item.isVegetarian
                                ? const Color(0xFF00C853)
                                : const Color(0xFFD32F2F),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Dish & Photo',
                  onPressed: () =>
                      _openAddOrEditDishSheet(existingDish: item),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete Dish',
                  onPressed: () => _deleteDish(item),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
