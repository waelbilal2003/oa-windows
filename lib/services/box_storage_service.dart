import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/box_model.dart';
import 'package:flutter/foundation.dart';

class BoxStorageService {
  // الآن نعيد المسار الأساسي لمجلد "MarketLedger/BoxJournals" مباشرة
  Future<String> _getBasePath() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      // Windows, iOS, macOS, Linux تستخدم مجلد المستندات
      directory = await getApplicationDocumentsDirectory();
    }

    final basePath = '${directory!.path}/MarketLedger/BoxJournals';
    final folder = Directory(basePath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return basePath;
  }

  // اسم الملف يعتمد على التاريخ فقط (مثل بقية الخدمات)
  String _createFileName(String date) {
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');
    return 'box-$formattedDate.json';
  }

  Future<bool> saveBoxDocument(BoxDocument document) async {
    try {
      final basePath = await _getBasePath(); // المسار الكامل الآن
      final fileName = _createFileName(document.date);
      final filePath = '$basePath/$fileName';
      final file = File(filePath);
      final jsonString = jsonEncode(document.toJson());
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ يومية الصندوق: $e');
      return false;
    }
  }

  Future<BoxDocument?> loadBoxDocumentForDate(String date) async {
    try {
      final basePath = await _getBasePath();
      final fileName = _createFileName(date);
      final filePath = '$basePath/$fileName';

      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return BoxDocument.fromJson(jsonMap);
    } catch (e) {
      debugPrint('❌ خطأ في قراءة يومية الصندوق: $e');
      return null;
    }
  }

  // *** تمت إعادتها وتكييفها: تعمل الآن مع الهيكل الجديد ***
  Future<BoxDocument?> loadBoxDocument(String date, String recordNumber) async {
    // تتجاهل recordNumber لأن هناك ملف واحد فقط لكل يوم
    return await loadBoxDocumentForDate(date);
  }

  // *** تمت إعادتها وتكييفها: تعمل الآن مع الهيكل الجديد ***
  Future<List<String>> getAvailableRecords(String date) async {
    try {
      final document = await loadBoxDocumentForDate(date);
      if (document != null) {
        // إذا وجد الملف، نرجع رقم سجله في قائمة
        return [document.recordNumber];
      }
      // إذا لم يوجد الملف، نرجع قائمة فارغة
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة سجلات الصندوق: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, String>>> getAvailableDatesWithNumbers() async {
    try {
      final basePath = await _getBasePath();
      final folder = Directory(basePath);
      if (!await folder.exists()) {
        return [];
      }

      final files = await folder.list().toList();
      final datesWithNumbers = <Map<String, String>>[];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            final date = jsonMap['date']?.toString() ?? '';
            final journalNumber = jsonMap['recordNumber']?.toString() ?? '1';
            if (date.isNotEmpty) {
              datesWithNumbers.add({
                'date': date,
                'journalNumber': journalNumber,
              });
            }
          } catch (e) {
            // تجاهل الملفات التالفة
          }
        }
      }

      datesWithNumbers.sort((a, b) {
        final numA = int.tryParse(a['journalNumber'] ?? '0') ?? 0;
        final numB = int.tryParse(b['journalNumber'] ?? '0') ?? 0;
        return numA.compareTo(numB);
      });

      return datesWithNumbers;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة تواريخ الصندوق: $e');
      return [];
    }
  }

  Future<String?> getFilePath(String date) async {
    try {
      final basePath = await _getBasePath();
      final fileName = _createFileName(date);
      final filePath = '$basePath/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على مسار ملف الصندوق: $e');
      return null;
    }
  }

  Future<String> getJournalNumberForDate(String date) async {
    try {
      final document = await loadBoxDocumentForDate(date);
      return document?.recordNumber ?? '1';
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على رقم يومية الصندوق: $e');
      return '1';
    }
  }

  Future<String> getNextJournalNumber() async {
    try {
      final basePath = await _getBasePath();
      final folder = Directory(basePath);
      if (!await folder.exists()) {
        return '1';
      }

      final files = await folder.list().toList();
      int maxJournalNumber = 0;

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            final journalNumber =
                int.tryParse(jsonMap['recordNumber'] ?? '0') ?? 0;
            if (journalNumber > maxJournalNumber) {
              maxJournalNumber = journalNumber;
            }
          } catch (e) {
            // تجاهل الملفات التالفة
          }
        }
      }
      return (maxJournalNumber + 1).toString();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الرقم التسلسلي التالي للصندوق: $e');
      return '1';
    }
  }
}
