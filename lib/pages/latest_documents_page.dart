import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_scanner_card_app/core/colors.dart';
import 'package:flutter_scanner_card_app/core/spaces.dart';
import 'package:flutter_scanner_card_app/data/models/document_model.dart';
import 'package:flutter_scanner_card_app/pages/detail_document_page.dart';

class LatestDocumentsPage extends StatefulWidget {
  final List<DocumentModel> documents;

  const LatestDocumentsPage({
    super.key,
    required this.documents,
  });

  @override
  State<LatestDocumentsPage> createState() => _LatestDocumentsPageState();
}

class _LatestDocumentsPageState extends State<LatestDocumentsPage> {
  // Fungsi untuk menghapus dokumen dari daftar setelah dihapus
  void _removeDocument(int documentId) {
    setState(() {
      widget.documents.removeWhere((doc) => doc.id == documentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.documents.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (context, index) {
        final document = widget.documents[index];
        return Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailDocumentPage(
                    document: document,
                    onDocumentDeleted: () => _removeDocument(document
                        .id!), // Panggil callback ketika dokumen dihapus
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      width: double.infinity,
                      File(document.path!),
                      fit: BoxFit.cover,
                      colorBlendMode: BlendMode.colorBurn,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                ),
                const SpaceHeight(4),
                Text(
                  document.name!,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
