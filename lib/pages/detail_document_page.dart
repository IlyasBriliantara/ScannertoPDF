import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_scanner_card_app/core/colors.dart';
import 'package:flutter_scanner_card_app/core/spaces.dart';
import 'package:flutter_scanner_card_app/data/models/document_model.dart';
import 'package:flutter_scanner_card_app/data/datasources/document_local_datasource.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  bool _isDownloaded = false; // Tambahkan variabel ini

  // Fungsi untuk membuat dan menyimpan file PDF
  Future<void> _downloadDocument() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Minta izin untuk mengakses penyimpanan
      if (await _requestStoragePermission()) {
        // Dapatkan direktori Download
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          // Untuk Android, gunakan MediaStore atau folder Downloads umum
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
            downloadsDir = Directory('${downloadsDir?.path}/Download');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
          }
        } else {
          // Untuk platform lain (misalnya iOS), gunakan getDownloadsDirectory()
          downloadsDir = await getDownloadsDirectory();
        }

        if (downloadsDir == null) {
          throw Exception('Tidak dapat menemukan direktori Download');
        }

        // Buat dokumen PDF
        final pdf = pw.Document();
        final imageFile = File(widget.document.path!);
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(
              child: pw.Image(image),
            ),
          ),
        );

        // Simpan file PDF ke folder Download
        final sanitizedFileName = widget.document.name!
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'); // Sanitasi nama file
        final filePath = '${downloadsDir.path}/$sanitizedFileName.pdf';
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dokumen berhasil diunduh ke $filePath')),
        );

        setState(() {
          _isDownloaded = true; // Set menjadi true setelah berhasil diunduh
        });
      } else {
        // Tampilkan pesan jika izin ditolak
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak')),
        );
      }
    } catch (e) {
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh dokumen: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  // Fungsi untuk meminta izin penyimpanan
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      } else {
        var status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
    } else {
      // Untuk platform lain, minta izin penyimpanan standar
      if (await Permission.storage.isGranted) {
        return true;
      } else {
        var status = await Permission.storage.request();
        return status.isGranted;
      }
    }
  }

  // Fungsi penghapusan yang sudah ada
  Future<void> _deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Konfirmasi",
          style: TextStyle(color: AppColors.primary),
        ),
        content: const Text('Apakah Anda yakin ingin menghapus dokumen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Hapus",
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
          const SnackBar(content: Text('Dokumen berhasil dihapus')),
        );

        widget.onDocumentDeleted();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus dokumen: $e')),
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
        title: const Text('Document Details'),
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
            onPressed: _isDownloading ? null : _downloadDocument,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.document.name ?? 'Unnamed Document',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(widget.document.path!),
              width: double.infinity,
              fit: BoxFit.contain,
              colorBlendMode: BlendMode.colorBurn,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          const SpaceHeight(12),
          if (_isDownloaded) // Jika dokumen sudah diunduh, tampilkan tombol share
            ElevatedButton(
              onPressed: () {
                // Tombol bisa ditekan namun tidak melakukan apapun
              },
              child: const Text(
                "Share",
                style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
