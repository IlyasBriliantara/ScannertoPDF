import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_scanner_card_app/core/colors.dart';
import 'package:flutter_scanner_card_app/data/datasources/document_local_datasource.dart';
import 'package:flutter_scanner_card_app/data/models/document_model.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:intl/intl.dart';

class SaveDocumentPage extends StatefulWidget {
  final String pathImage;
  const SaveDocumentPage({
    Key? key,
    required this.pathImage,
  }) : super(key: key);

  @override
  State<SaveDocumentPage> createState() => _SaveDocumentPageState();
}

class _SaveDocumentPageState extends State<SaveDocumentPage> {
  TextEditingController? nameController;
  String? selectCategory;
  List<String> scannedImages = [];

  final List<String> categories = [
    'Card',
    'Note',
    'Mail',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    // Add the initial scanned image to the list
    scannedImages.add(widget.pathImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Document'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Display all scanned images
          SizedBox(
            width: double.infinity,
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: scannedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(scannedImages[index])),
                  ),
                );
              },
            ),
          ),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Document Name',
            ),
          ),
          const SizedBox(
            height: 16.0,
          ),
          DropdownButtonFormField<String>(
            value: selectCategory,
            onChanged: (String? value) {
              setState(() {
                selectCategory = value;
              });
            },
            items: categories
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Category',
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Add More" button
          InkWell(
            onTap: () async {
              DocumentScannerOptions documentOptions = DocumentScannerOptions(
                documentFormat: DocumentFormat.jpeg,
                mode: ScannerMode.filter,
                pageLimit: 1,
                isGalleryImport: true,
              );
              final documentScanner = DocumentScanner(options: documentOptions);
              DocumentScanningResult result =
                  await documentScanner.scanDocument();
              final images = result.images;

              // Add the new scanned image to the list
              if (images.isNotEmpty) {
                setState(() {
                  scannedImages.add(images[0]);
                });
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  "Add More",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          // "Save" button
          InkWell(
            onTap: () {
              // Here, you would combine or handle the multiple scanned images as needed (e.g., saving them as separate files or as a single document).
              DocumentModel model = DocumentModel(
                name: nameController!.text,
                path: scannedImages
                    .join(','), // You can adjust how to store paths
                category: selectCategory!,
                createdAt:
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
              );
              DocumentLocalDatasource.instance.saveDocument(model);
              Navigator.pop(
                context,
              );
              const snackBar = SnackBar(
                content: Text('Document Saved'),
                backgroundColor: AppColors.primary,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 52,
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
