import 'package:equatable/equatable.dart';

enum ItemCategory {
  furniture('Furniture', 20000),
  appliance('Appliance', 15000),
  boxes('Boxes', 2500),
  other('Other', 8000);

  const ItemCategory(this.label, this.defaultUnitPrice);
  final String label;

  /// Price used for items that aren't in the [ItemCatalog].
  final int defaultUnitPrice;
}

/// Something the user is moving, e.g. "Boxes (medium) ×12".
class MoveItem extends Equatable {
  const MoveItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
    this.quantity = 1,
  });

  final String id;
  final String name;
  final ItemCategory category;

  /// Moving cost per unit in RWF.
  final int unitPrice;
  final int quantity;

  int get total => unitPrice * quantity;

  MoveItem copyWith({int? quantity}) => MoveItem(
    id: id,
    name: name,
    category: category,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
  );

  @override
  List<Object?> get props => [id, name, category, unitPrice, quantity];
}

/// Known items with their category and per-unit moving price.
abstract final class ItemCatalog {
  static const _entries = <String, (ItemCategory, int)>{
    'sofa': (ItemCategory.furniture, 25000),
    'bed': (ItemCategory.furniture, 30000),
    'mattress': (ItemCategory.furniture, 12000),
    'wardrobe': (ItemCategory.furniture, 25000),
    'table': (ItemCategory.furniture, 12000),
    'chair': (ItemCategory.furniture, 4000),
    'desk': (ItemCategory.furniture, 15000),
    'shelf': (ItemCategory.furniture, 10000),
    'fridge': (ItemCategory.appliance, 20000),
    'freezer': (ItemCategory.appliance, 22000),
    'cooker': (ItemCategory.appliance, 15000),
    'washing machine': (ItemCategory.appliance, 18000),
    'tv': (ItemCategory.appliance, 10000),
    'microwave': (ItemCategory.appliance, 6000),
    'box': (ItemCategory.boxes, 2500),
    'bag': (ItemCategory.boxes, 2000),
    'bicycle': (ItemCategory.other, 8000),
    'motorcycle': (ItemCategory.other, 30000),
    'plant': (ItemCategory.other, 3000),
  };

  /// Matches the first catalog keyword contained in [name]
  /// ("Bed and mattress" → bed). Unknown items fall back to "Other".
  static (ItemCategory, int) lookup(String name) {
    final lower = name.toLowerCase();
    for (final MapEntry(:key, :value) in _entries.entries) {
      if (RegExp('\\b$key').hasMatch(lower)) return value;
    }
    return (ItemCategory.other, ItemCategory.other.defaultUnitPrice);
  }
}
