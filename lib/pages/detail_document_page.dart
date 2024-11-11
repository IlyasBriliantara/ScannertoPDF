import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_scanner_card_app/core/colors.dart';
import 'package:flutter_scanner_card_app/core/spaces.dart';
import 'package:flutter_scanner_card_app/data/models/document_model.dart';
import 'package:flutter_scanner_card_app/data/datasources/document_local_datasource.dart';
import 'package:flutter_scanner_card_app/pages/save_document_page.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailDocumentPage extends StatefulWidget {
  final DocumentModel document;
  final VoidCallback onDocumentDeleted;

  const DetailDocumentPage({
    super.key,
    required this.document,
    required this.onDocumentDeleted,
  });

  @override
  State<DetailDocumentPage> createState() => _DetailDocumentPageState();
}

class _DetailDocumentPageState extends State<DetailDocumentPage> {
  bool _isDeleting = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _downloadedFilePath;
  String? _selectedPageSize;

  @override
  void initState() {
    super.initState();
    _loadDownloadStatus();
  }

  List<String> _getScannedImages() {
    return widget.document.path?.split(',') ?? [];
  }

  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(16),
          content: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(imagePath)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageListView() {
    final images = _getScannedImages();
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _showFullImage(images[index]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(images[index])),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadDownloadStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? filePath =
        prefs.getString('downloadedFilePath_${widget.document.id}');
    setState(() {
      _isDownloaded = filePath != null;
      _downloadedFilePath = filePath;
    });
  }

  Future<void> _saveDownloadStatus(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloadedFilePath_${widget.document.id}', filePath);
    setState(() {
      _isDownloaded = true;
      _downloadedFilePath = filePath;
    });
  }

  // Menampilkan popup pilihan ukuran halaman
  // Modifikasi pada fungsi _showPageSizeDialog
  Future<void> _showPageSizeDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Atur lebar maksimum dialog berdasarkan ukuran layar
            double dialogWidth =
                constraints.maxWidth > 300 ? 300 : constraints.maxWidth * 0.9;
            return AlertDialog(
              title: const Text(
                'Select Page Size',
                style: TextStyle(color: AppColors.primary),
              ),
              content: SizedBox(
                width: dialogWidth,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: const Text('Custom (Without Margin)'),
                          value: 'custom',
                          groupValue: _selectedPageSize,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedPageSize = value;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('A4 (With Margin)'),
                          value: 'A4',
                          groupValue: _selectedPageSize,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedPageSize = value;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _downloadDocument();
                  },
                  child: const Text(
                    'Download',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi unduh dokumen yang telah diubah agar mendukung pilihan ukuran halaman
  Future<void> _downloadDocument() async {
    if (_isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dokumen sudah diunduh di $_downloadedFilePath'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      if (await _requestStoragePermission()) {
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
            downloadsDir = Directory('${downloadsDir?.path}/Download');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
          }
        } else {
          downloadsDir = await getDownloadsDirectory();
        }

        if (downloadsDir == null) {
          throw Exception('Cannot find the Download directory');
        }

        final pdf = pw.Document();
        List<String> imagePaths = widget.document.path!.split(',');

        for (var path in imagePaths) {
          final imageFile = File(path);
          final imageBytes = await imageFile.readAsBytes();
          final image = pw.MemoryImage(imageBytes);

          if (_selectedPageSize == 'A4') {
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context context) {
                  return pw.Center(
                      child: pw.Image(image, fit: pw.BoxFit.contain));
                },
                margin: pw.EdgeInsets.all(20),
              ),
            );
          } else {
            final decodedImage = await decodeImageFromList(imageBytes);
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(decodedImage.width.toDouble(),
                    decodedImage.height.toDouble()),
                build: (pw.Context context) {
                  return pw.Center(child: pw.Image(image, fit: pw.BoxFit.fill));
                },
                margin: pw.EdgeInsets.zero,
              ),
            );
          }
        }

        final sanitizedFileName =
            widget.document.name!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final filePath = '${downloadsDir.path}/$sanitizedFileName.pdf';
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        await _saveDownloadStatus(filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document successfully downloaded to $filePath'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permit denied'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download the document: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _shareDocument() async {
    if (!_isDownloaded) {
      await _showPageSizeDialog();
    } else {
      final file = File(_downloadedFilePath!);

      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found'),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      }

      try {
        final XFile downloadedFile = XFile(_downloadedFilePath!);
        await Share.shareXFiles(
          [downloadedFile],
          text: 'View this document!',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document sharing failure: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<bool> _isAppInstalled(String packageName) async {
    if (Platform.isAndroid) {
      try {
        final uri = Uri.parse('package:$packageName');
        return true;
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      } else {
        var status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
    } else {
      if (await Permission.storage.isGranted) {
        return true;
      } else {
        var status = await Permission.storage.request();
        return status.isGranted;
      }
    }
  }

  Future<void> _deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Confirmation",
          style: TextStyle(color: AppColors.primary),
        ),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Delete",
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await DocumentLocalDatasource.instance
            .deleteDocument(widget.document.id!);

        final file = File(widget.document.path!);
        if (await file.exists()) {
          await file.delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onDocumentDeleted();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete the document: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      } finally {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details Document'),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _deleteDocument,
          ),
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _showPageSizeDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.document.name ?? 'Unnamed Documents',
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SpaceHeight(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.document.category ?? 'Uncategorized',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: AppColors.primary,
                ),
              ),
              Text(
                widget.document.createdAt ?? '',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SpaceHeight(12),
          _buildImageListView(),
          const SpaceHeight(12),
          ElevatedButton.icon(
            onPressed: _shareDocument,
            icon: const Icon(Icons.share, color: AppColors.primary),
            label: const Text(
              "Share",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
