import 'package:flutter/material.dart';

import '../../core/models/water_product.dart';

class HomeSearchDelegate extends SearchDelegate<WaterProduct?> {
  final List<WaterProduct> allProducts;
  final Function(WaterProduct) onProductTap;

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
              leading: Image.asset(p.image, width: 40),
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
