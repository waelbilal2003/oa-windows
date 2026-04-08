import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class PdfActionMenu extends StatelessWidget {
  final Future<List<dynamic>> Function() getItems;
  final Future<Uint8List> Function(List<dynamic>) generatePdfCallback;
  final String supplierOrCustomerName;
  final String filterDesc;
  final double? balance;
  final String storeName;
  final String selectedDate;
  final String type; // 'supplier' or 'customer'

  const PdfActionMenu({
    Key? key,
    required this.getItems,
    required this.generatePdfCallback,
    required this.supplierOrCustomerName,
    required this.filterDesc,
    required this.balance,
    required this.storeName,
    required this.selectedDate,
    required this.type,
  }) : super(key: key);

  Future<Uint8List> _generatePdfBytes() async {
    final items = await getItems();
    if (items.isEmpty) throw Exception('لا توجد بيانات');
    return await generatePdfCallback(items);
  }

  Future<void> _sharePdf() async {
    try {
      final pdfBytes = await _generatePdfBytes();
      final output = await getTemporaryDirectory();
      final fileName = type == 'supplier'
          ? 'مشتريات_$supplierOrCustomerName.pdf'
          : 'فاتورة_$supplierOrCustomerName.pdf';
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)],
          text: type == 'supplier'
              ? 'مشتريات المورد $supplierOrCustomerName - $filterDesc'
              : 'فاتورة الزبون $supplierOrCustomerName - $filterDesc');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _savePdf() async {
    try {
      final pdfBytes = await _generatePdfBytes();
      final output = await getDownloadsDirectory();
      if (output == null) throw Exception('لا يمكن الوصول إلى مجلد التنزيلات');
      final fileName = type == 'supplier'
          ? 'مشتريات_$supplierOrCustomerName.pdf'
          : 'فاتورة_$supplierOrCustomerName.pdf';
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _printPdf() async {
    try {
      final pdfBytes = await _generatePdfBytes();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: type == 'supplier'
            ? 'مشتريات_المورد_$supplierOrCustomerName.pdf'
            : 'فاتورة_الزبون_$supplierOrCustomerName.pdf',
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.picture_as_pdf),
      tooltip: 'خيارات PDF',
      onSelected: (value) async {
        try {
          switch (value) {
            case 'share':
              await _sharePdf();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت المشاركة بنجاح')),
                );
              }
              break;
            case 'save':
              await _savePdf();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ PDF في مجلد التنزيلات')),
                );
              }
              break;
            case 'print':
              await _printPdf();
              break;
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
            );
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, color: Colors.blue),
              SizedBox(width: 12),
              Text('مشاركة PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'save',
          child: Row(
            children: [
              Icon(Icons.save_alt, color: Colors.green),
              SizedBox(width: 12),
              Text('حفظ على الكمبيوتر'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print, color: Colors.purple),
              SizedBox(width: 12),
              Text('طباعة مباشرة'),
            ],
          ),
        ),
      ],
    );
  }
}
