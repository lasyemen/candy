import 'package:flutter/material.dart';

import '../../models/index.dart';

class HomeSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> allProducts;
  final Function(Product) onProductTap;

  HomeSearchDelegate({required this.allProducts, required this.onProductTap})
    : super(
        searchFieldLabel: 'بحث المنتجات ...',
        textInputAction: TextInputAction.search,
      );

  @override
  Widget buildResults(BuildContext context) {
    final result = allProducts
        .where((p) => p.name.contains(query.trim()))
        .toList();
    if (result.isEmpty) {
      return const Center(child: Text('لا يوجد نتائج لهذا البحث.'));
    }
    return ListView(
      children: result
          .map(
            (p) => ListTile(
              title: Text(p.name),
              subtitle: Text('${p.price} ر.س'),
              leading: p.imageUrl != null
                  ? Image.network(p.imageUrl!, width: 40)
                  : const Icon(Icons.image),
              onTap: () {
                onProductTap(p);
                close(context, p);
              },
            ),
          )
          .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.close), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
}
