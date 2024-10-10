import 'package:flutter/material.dart';
import 'package:flutter_scanner_card_app/pages/document_category_page.dart';

import 'category_button.dart';

class MenuCategories extends StatelessWidget {
  const MenuCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: CategoryButton(
            imagePath: null,
            label: 'Card',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const DocumentCategoryPage(categoryTitle: 'Card')));
            },
          ),
        ),
        Flexible(
          child: CategoryButton(
            imagePath: null,
            label: 'Note',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const DocumentCategoryPage(categoryTitle: 'Note')));
            },
          ),
        ),
        Flexible(
          child: CategoryButton(
            imagePath: null,
            label: 'Mail',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const DocumentCategoryPage(categoryTitle: 'Mail')));
            },
          ),
        ),
      ],
    );
  }
}
