import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_scanner_card_app/core/colors.dart';
import 'package:flutter_scanner_card_app/data/datasources/document_local_datasource.dart';
import 'package:flutter_scanner_card_app/data/models/document_model.dart';
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

  final List<String> categories = [
    'Card',
    'Note',
    'Mail',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
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
          SizedBox(
              width: double.infinity,
              height: 200,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(widget.pathImage)))),
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
      bottomNavigationBar: InkWell(
        onTap: () {
          DocumentModel model = DocumentModel(
            name: nameController!.text,
            path: widget.pathImage,
            category: selectCategory!,
            createdAt: DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now()),
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
    );
  }
}