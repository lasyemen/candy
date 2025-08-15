import 'package:flutter/material.dart';

class SliverTitleAppBar extends StatelessWidget {
  final String title;
  final Color? backgroundColor;

  const SliverTitleAppBar({super.key, required this.title, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
    );
  }
}


