import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExcelImportService {
  static const Map<String, String> _columnMapping = {
    'เลขบัตรประจำตัวประชาชน': 'idCard',
    'เลขประจำตัวประชาชน': 'idCard',
    'บัตรประจำตัวประชาชน': 'idCard',
    'เลขบัตร': 'idCard',
    'ID Card': 'idCard',
   
    'ชื่อ-นามสกุล': 'name',
    'ชื่อนามสกุล': 'name',
    'ชื่อ': 'name',
    'Name': 'name',
   
    'ที่อยู่': 'address',
    'Address': 'address',
   
    'เบอร์โทร': 'phone',
    'เบอร์โทรศัพท์': 'phone',
    'เบอร์มือถือ': 'phone',
    'โทรศัพท์': 'phone',
    'Phone': 'phone',
   
    'อายุ': 'age',
    'Age': 'age',
   
    'เพศ': 'gender',
    'Gender': 'gender',
   
    'น้ำหนัก': 'weight',
    'Weight': 'weight',
   
    'ส่วนสูง': 'height',
    'Height': 'height',
   
    'โรคประจำตัว': 'ncds',
    'โรค NCDs': 'ncds',
    'NCDs': 'ncds',
    'โรค': 'ncds',
    'Disease': 'ncds',
   
    'หมู่บ้าน': 'village',
    'ชุมชน': 'village',
    'Village': 'village',
   
    'ตำบล': 'subDistrict',
    'Sub District': 'subDistrict',
   
    'อำเภอ': 'district',
    'District': 'district',
   
    'จังหวัด': 'province',
    'Province': 'province',
   
    'ความเก่งเทคโนโลยี': 'techLevel',
    'ระดับเทคโนโลยี': 'techLevel',
    'Tech Level': 'techLevel',
    'เทคโนโลยี': 'techLevel',
  };

  // ================= Download Template with Data =================
  static Future<DownloadResult> downloadTemplate(BuildContext context) async {
    try {
      // ขออนุญาตการเขียนไฟล์
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return DownloadResult(
              success: false, 
              message: 'ไม่ได้รับอนุญาตให้เข้าถึงที่เก็บไฟล์'
            );
          }
        }
      }

      // สร้าง Excel file
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Template'];

      // ลบ sheet เริ่มต้น
      excel.delete('Sheet1');

      // สร้าง header row
      final headers = [
        'เลขบัตรประจำตัวประชาชน',
        'ชื่อ-นามสกุล',
        'ที่อยู่',
        'เบอร์โทร',
        'อายุ',
        'เพศ',
        'น้ำหนัก',
        'ส่วนสูง',
        'โรคประจำตัว',
        'หมู่บ้าน',
        'ตำบล',
        'อำเภอ',
        'จังหวัด',
        'ความเก่งเทคโนโลยี'
      ];

      // เพิ่ม headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        
        // จัดรูปแบบ header
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: '#10B981',
          fontColorHex: '#FFFFFF',
        );
      }

      // ดึงข้อมูลจาก Firebase
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      // เพิ่มข้อมูลลงใน Excel
      for (int i = 0; i < usersSnapshot.docs.length; i++) {
        final doc = usersSnapshot.docs[i];
        final userData = doc.data() as Map<String, dynamic>;
        final rowIndex = i + 1;

        // เพิ่มข้อมูลในแต่ละคอลัมน์
        _addCellValue(sheet, rowIndex, 0, userData['idCard']);
        _addCellValue(sheet, rowIndex, 1, userData['name']);
        _addCellValue(sheet, rowIndex, 2, userData['address']);
        _addCellValue(sheet, rowIndex, 3, userData['phone']);
        _addCellValue(sheet, rowIndex, 4, userData['age']);
        _addCellValue(sheet, rowIndex, 5, _formatGender(userData['gender']));
        _addCellValue(sheet, rowIndex, 6, userData['weight']);
        _addCellValue(sheet, rowIndex, 7, userData['height']);
        _addCellValue(sheet, rowIndex, 8, userData['ncds']);
        _addCellValue(sheet, rowIndex, 9, userData['village']);
        _addCellValue(sheet, rowIndex, 10, userData['subDistrict']);
        _addCellValue(sheet, rowIndex, 11, userData['district']);
        _addCellValue(sheet, rowIndex, 12, userData['province']);
        _addCellValue(sheet, rowIndex, 13, _formatTechLevel(userData['techLevel']));
      }

      // ปรับความกว้างของคอลัมน์
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      // เพิ่มคำอธิบายใน sheet แยก
      _addInstructionSheet(excel);

      // บันทึกไฟล์
      final bytes = excel.encode()!;
      final fileName = 'users_template_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      String? filePath;
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile platforms
        final directory = await getExternalStorageDirectory() ?? 
                         await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      } else {
        // Desktop/Web platforms
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'บันทึก Template',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(bytes),
        );
        filePath = result;
      }

      if (filePath != null) {
        return DownloadResult(
          success: true,
          message: 'ดาวน์โหลด template สำเร็จ\nบันทึกที่: $filePath',
          filePath: filePath,
          totalRecords: usersSnapshot.docs.length,
        );
      } else {
        return DownloadResult(
          success: false,
          message: 'ยกเลิกการบันทึกไฟล์'
        );
      }

    } catch (e) {
      return DownloadResult(
        success: false,
        message: 'เกิดข้อผิดพลาดในการสร้าง template: $e'
      );
    }
  }

  // ================= Download Empty Template =================
  static Future<DownloadResult> downloadEmptyTemplate(BuildContext context) async {
    try {
      // ขออนุญาตการเขียนไฟล์
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return DownloadResult(
              success: false, 
              message: 'ไม่ได้รับอนุญาตให้เข้าถึงที่เก็บไฟล์'
            );
          }
        }
      }

      // สร้าง Excel file
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Template'];

      // ลบ sheet เริ่มต้น
      excel.delete('Sheet1');

      // สร้าง header row
      final headers = [
        'เลขบัตรประจำตัวประชาชน',
        'ชื่อ-นามสกุล',
        'ที่อยู่',
        'เบอร์โทร',
        'อายุ',
        'เพศ',
        'น้ำหนัก',
        'ส่วนสูง',
        'โรคประจำตัว',
        'หมู่บ้าน',
        'ตำบล',
        'อำเภอ',
        'จังหวัด',
        'ความเก่งเทคโนโลยี'
      ];

      // เพิ่ม headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        
        // จัดรูปแบบ header
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: '#10B981',
          fontColorHex: '#FFFFFF',
        );
      }

      // เพิ่มตัวอย่างข้อมูล
      final sampleData = [
        ['1234567890123', 'นายตัวอย่าง ใช้งาน', '123 หมู่ 1', '0812345678', '30', 'ชาย', '70', '170', 'ไม่มี', 'หมู่บ้านตัวอย่าง', 'ตำบลตัวอย่าง', 'อำเภอตัวอย่าง', 'จังหวัดตัวอย่าง', 'ปานกลาง'],
        ['9876543210987', 'นางสาวตัวอย่าง ทดสอบ', '456 หมู่ 2', '0898765432', '25', 'หญิง', '55', '160', 'เบาหวาน', 'หมู่บ้านทดสอบ', 'ตำบลทดสอบ', 'อำเภอทดสอบ', 'จังหวัดทดสอบ', 'เก่งเทคโนโลยี'],
      ];

      for (int rowIndex = 0; rowIndex < sampleData.length; rowIndex++) {
        final rowData = sampleData[rowIndex];
        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          _addCellValue(sheet, rowIndex + 1, colIndex, rowData[colIndex]);
        }
      }

      // ปรับความกว้างของคอลัมน์
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      // เพิ่มคำอธิบายใน sheet แยก
      _addInstructionSheet(excel);

      // บันทึกไฟล์
      final bytes = excel.encode()!;
      final fileName = 'empty_template_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      String? filePath;
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile platforms
        final directory = await getExternalStorageDirectory() ?? 
                         await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      } else {
        // Desktop/Web platforms
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'บันทึก Template',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(bytes),
        );
        filePath = result;
      }

      if (filePath != null) {
        return DownloadResult(
          success: true,
          message: 'ดาวน์โหลด template ว่างสำเร็จ\nบันทึกที่: $filePath',
          filePath: filePath,
          totalRecords: 2, // ตัวอย่างข้อมูล
        );
      } else {
        return DownloadResult(
          success: false,
          message: 'ยกเลิกการบันทึกไฟล์'
        );
      }

    } catch (e) {
      return DownloadResult(
        success: false,
        message: 'เกิดข้อผิดพลาดในการสร้าง template: $e'
      );
    }
  }

  // ================= import Excel with Edit Option =================
  static Future<ImportResult> importExcelFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || (result.files.single.bytes == null && result.files.single.path == null)) {
        return ImportResult(
          success: false,
          message: 'ไม่ได้เลือกไฟล์',
        );
      }

      final bytes = result.files.single.bytes ??
          await File(result.files.single.path!).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return ImportResult(success: false, message: 'ไฟล์ Excel ไม่มีข้อมูล');
      }

      final sheet = excel.tables.entries.first.value;

      if (sheet.rows.isEmpty) {
        return ImportResult(success: false, message: 'Sheet นี้ไม่มีข้อมูล');
      }

      final headerRow = sheet.rows[0];
      final Map<int, String> columnMap = {};

      for (int i = 0; i < headerRow.length; i++) {
        final cellValue = headerRow[i]?.value?.toString().trim() ?? '';
        if (cellValue.isNotEmpty) {
          final mappedField = _getMappedField(cellValue);
          if (mappedField != null) columnMap[i] = mappedField;
        }
      }

      if (columnMap.isEmpty) {
        return ImportResult(
          success: false,
          message: 'ไม่พบคอลัมน์ที่ตรงกับรูปแบบข้อมูลที่กำหนด\n\nคอลัมน์ที่รองรับ:\n${_getRequiredColumns()}',
        );
      }

      final requiredFields = ['idCard', 'name', 'phone', 'age'];
      final missingFields = requiredFields.where((f) => !columnMap.values.contains(f)).toList();

      if (missingFields.isNotEmpty) {
        return ImportResult(
          success: false,
          message: 'ขาดคอลัมน์ที่จำเป็น: ${missingFields.join(', ')}\n\nคอลัมน์ที่รองรับ:\n${_getRequiredColumns()}',
        );
      }

      final List<ImportDataItem> importData = [];
      final List<String> errors = [];
      int successCount = 0;
      int errorCount = 0;

      for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        final row = sheet.rows[rowIndex];
        try {
          final userData = _processRow(row, columnMap, rowIndex + 1);

          if (userData != null) {
            final duplicateInfo = await _checkDuplicateDetailed(userData['idCard'], userData['phone']);
           
            importData.add(ImportDataItem(
              data: userData,
              rowNumber: rowIndex + 1,
              duplicateInfo: duplicateInfo,
              isValid: duplicateInfo == null,
            ));

            if (duplicateInfo == null) {
              successCount++;
            } else {
              errorCount++;
            }
          }
        } catch (e) {
          errors.add('แถว ${rowIndex + 1}: $e');
          errorCount++;
        }
      }

      if (importData.isEmpty) {
        return ImportResult(
          success: false,
          message: 'ไม่มีข้อมูลที่ถูกต้องสำหรับการนำเข้า\n\nข้อผิดพลาด:\n${errors.take(10).join('\n')}',
          totalRows: sheet.rows.length - 1,
          errorCount: errorCount,
          errors: errors,
        );
      }

      // Show preview and edit dialog
      final processedData = await _showPreviewAndEditDialog(context, importData);
      if (processedData == null) {
        return ImportResult(success: false, message: 'ยกเลิกการนำเข้าข้อมูล');
      }

      final importResult = await _importToFirebaseWithUpdates(processedData);

      return ImportResult(
        success: true,
        message: 'นำเข้าข้อมูลสำเร็จ: ${importResult['success']} รายการ${importResult['failed'] > 0 ? ', ล้มเหลว: ${importResult['failed']} รายการ' : ''}',
        totalRows: sheet.rows.length - 1,
        successCount: importResult['success'] as int,
        errorCount: importResult['failed'] as int,
        errors: importResult['errors'],
      );
    } catch (e) {
      return ImportResult(success: false, message: 'เกิดข้อผิดพลาด: $e');
    }
  }

  // ================= Helper Methods =================
  static void _addCellValue(Sheet sheet, int row, int col, dynamic value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value != null) {
      cell.value = value.toString();
    }
  }

  static String _formatGender(dynamic gender) {
    if (gender == null) return '';
    final genderStr = gender.toString().toLowerCase();
    if (genderStr == 'female' || genderStr == 'หญิง') return 'หญิง';
    if (genderStr == 'male' || genderStr == 'ชาย') return 'ชาย';
    return gender.toString();
  }

  static String _formatTechLevel(dynamic techLevel) {
    if (techLevel == null) return '';
    final techStr = techLevel.toString().toLowerCase();
    switch (techStr) {
      case 'beginner':
        return 'ไม่เก่ง';
      case 'intermediate':
        return 'ปานกลาง';
      case 'advanced':
        return 'เก่งเทคโนโลยี';
      default:
        return techLevel.toString();
    }
  }

  static void _addInstructionSheet(Excel excel) {
    final instructionSheet = excel['คำอธิบาย'];
    
    final instructions = [
      'คำอธิบายการใช้งาน Template',
      '',
      'คอลัมน์ที่จำเป็น (ต้องมี):',
      '- เลขบัตรประจำตัวประชาชน: เลข 13 หลัก',
      '- ชื่อ-นามสกุล: ชื่อและนามสกุลเต็ม',
      '- เบอร์โทร: เลข 10 หลัก (เช่น 0812345678)',
      '- อายุ: ตัวเลขเท่านั้น',
      '',
      'คอลัมน์เสริม (ไม่บังคับ):',
      '- ที่อยู่: ที่อยู่เต็ม',
      '- เพศ: ชาย หรือ หญิง',
      '- น้ำหนัก: ตัวเลข (กิโลกรัม)',
      '- ส่วนสูง: ตัวเลข (เซนติเมตร)',
      '- โรคประจำตัว: ชื่อโรค หรือ ไม่มี',
      '- หมู่บ้าน: ชื่อหมู่บ้าน/ชุมชน',
      '- ตำบล: ชื่อตำบล',
      '- อำเภอ: ชื่ออำเภอ',
      '- จังหวัด: ชื่อจังหวัด',
      '- ความเก่งเทคโนโลยี: ไม่เก่ง, ปานกลาง, เก่งเทคโนโลยี',
      '',
      'หมายเหตุ:',
      '- กรุณาอย่าลบหรือเปลี่ยนชื่อคอลัมน์',
      '- ลบข้อมูลตัวอย่างออกก่อนใส่ข้อมูลจริง',
      '- บันทึกไฟล์เป็น .xlsx เท่านั้น',
    ];

    for (int i = 0; i < instructions.length; i++) {
      final cell = instructionSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
      cell.value = instructions[i];
      
      if (i == 0) {
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          fontColorHex: '#10B981',
        );
      } else if (instructions[i].startsWith('คอลัมน์') || instructions[i].startsWith('หมายเหตุ')) {
        cell.cellStyle = CellStyle(
          bold: true,
          fontColorHex: '#374151',
        );
      }
    }

    instructionSheet.setColumnWidth(0, 50.0);
  }

  // ================= Preview and Edit Dialog =================
  static Future<List<Map<String, dynamic>>?> _showPreviewAndEditDialog(
    BuildContext context,
    List<ImportDataItem> importData
  ) async {
    return await showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImportPreviewDialog(importData: importData),
    );
  }

  // ================= helper functions =================
  static String? _getMappedField(String columnName) {
    final normalized = columnName.trim().toLowerCase();
    for (final entry in _columnMapping.entries) {
      final key = entry.key.toLowerCase();
      if (normalized == key || normalized.contains(key) || key.contains(normalized)) {
        return entry.value;
      }
    }
    return null;
  }

  static String _getRequiredColumns() {
    return '''
คอลัมน์ที่จำเป็น:
- เลขบัตรประจำตัวประชาชน / เลขประจำตัวประชาชน
- ชื่อ-นามสกุล / ชื่อนามสกุล / ชื่อ
- เบอร์โทร / เบอร์โทรศัพท์ / เบอร์มือถือ
- อายุ

คอลัมน์เพิ่มเติม (ไม่บังคับ):
- ที่อยู่
- เพศ
- น้ำหนัก
- ส่วนสูง
- โรคประจำตัว / โรค NCDs
- หมู่บ้าน / ชุมชน
- ตำบล
- อำเภอ
- จังหวัด
- ความเก่งเทคโนโลยี
''';
  }

  static Map<String, dynamic>? _processRow(List<Data?> row, Map<int, String> columnMap, int rowNumber) {
    final Map<String, dynamic> userData = {};
    for (int i = 0; i < row.length; i++) {
      if (columnMap.containsKey(i)) {
        final val = row[i]?.value?.toString().trim();
        if (val != null && val.isNotEmpty) userData[columnMap[i]!] = val;
      }
    }
    if (!userData.containsKey('idCard') || !userData.containsKey('name') || !userData.containsKey('phone') || !userData.containsKey('age')) {
      throw Exception('ข้อมูลไม่ครบถ้วน');
    }
    return _validateAndTransformData(userData);
  }

  static String _normalizeTechLevel(dynamic value) {
    if (value == null) return 'beginner';
    final str = value.toString().toLowerCase().trim();
    if (str.contains('ไม่เก่ง') || str.contains('ไม่ใช้') || str.contains('ไม่รู้') ||
        str.contains('beginner') || str.contains('ต้องดูแล') || str == '1') {
      return 'beginner';
    }
    if (str.contains('ปานกลาง') || str.contains('โทรศัพท์') || str.contains('smartphone') ||
        str.contains('intermediate') || str == '2') {
      return 'intermediate';
    }
    if (str.contains('เก่งเทคโนโลยี') || str.contains('แอป') || str.contains('advanced') ||
        str.contains('computer') || str == '3') {
      return 'advanced';
    }
    return 'beginner';
  }

  static Map<String, dynamic> _validateAndTransformData(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    
    result['idCard'] = data['idCard'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    result['name'] = data['name'].toString();
    result['phone'] = data['phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    result['age'] = int.tryParse(data['age'].toString()) ?? 0;
    result['gender'] = data['gender']?.toString().toLowerCase().contains('หญิง') == true ? 'female' : 'male';
    result['weight'] = data['weight'] != null ? double.tryParse(data['weight'].toString()) : null;
    result['height'] = data['height'] != null ? double.tryParse(data['height'].toString()) : null;
    
    // แก้ไขการประมวลผล techLevel ให้ได้ค่า standard
    String techLevel = _normalizeTechLevel(data['techLevel']);
    result['techLevel'] = techLevel;
    result['needsSpecialCare'] = techLevel == 'beginner';
    
    result['address'] = data['address'] ?? '';
    result['ncds'] = data['ncds'] ?? '';
    result['village'] = data['village'] ?? '';
    result['subDistrict'] = data['subDistrict'] ?? '';
    result['district'] = data['district'] ?? '';
    result['province'] = data['province'] ?? '';
    
    if (result['weight'] != null && result['height'] != null) {
      final h = result['height'] as double;
      final w = result['weight'] as double;
      result['bmi'] = w / ((h / 100) * (h / 100));
    }
    
    return result;
  }

  static Future<DuplicateInfo?> _checkDuplicateDetailed(String idCard, String phone) async {
    final idQuery = await FirebaseFirestore.instance.collection('users').where('idCard', isEqualTo: idCard).get();
    if (idQuery.docs.isNotEmpty) {
      final doc = idQuery.docs.first;
      return DuplicateInfo(
        type: DuplicateType.idCard,
        existingData: doc.data(),
        docId: doc.id,
        message: 'พบเลขบัตรประชาชนซ้ำ',
      );
    }
   
    final phoneQuery = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).get();
    if (phoneQuery.docs.isNotEmpty) {
      final doc = phoneQuery.docs.first;
      return DuplicateInfo(
        type: DuplicateType.phone,
        existingData: doc.data(),
        docId: doc.id,
        message: 'พบเบอร์โทรศัพท์ซ้ำ',
      );
    }
   
    return null;
  }

  static Future<String?> _checkDuplicate(String idCard, String phone) async {
    final duplicateInfo = await _checkDuplicateDetailed(idCard, phone);
    return duplicateInfo?.message;
  }

  static Future<Map<String, dynamic>> _importToFirebaseWithUpdates(List<Map<String, dynamic>> userData) async {
    int success = 0, failed = 0;
    final errors = <String>[];

    for (final data in userData) {
      try {
        final docId = data.remove('_updateDocId');
       
        if (docId != null) {
          final updateData = Map<String, dynamic>.from(data);
          updateData['updatedAt'] = FieldValue.serverTimestamp();
         
          await FirebaseFirestore.instance
              .collection('users')
              .doc(docId)
              .update(updateData);
        } else {
          String mockEmail = "${data['phone']}@phone.local";
          String mockPassword = "phone_${data['phone']}";

          UserCredential? credential;
          try {
            credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: mockEmail,
              password: mockPassword,
            );
          } catch (e) {
            if (e.toString().contains('email-already-in-use')) {
              try {
                credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: mockEmail,
                  password: mockPassword,
                );
              } catch (loginError) {
                throw Exception('ไม่สามารถสร้างหรือเข้าสู่ระบบได้: ${loginError.toString()}');
              }
            } else {
              throw e;
            }
          }

          if (credential.user == null) {
            throw Exception('ไม่สามารถสร้าง Firebase Auth account ได้');
          }

          await credential.user!.updateDisplayName(data['name']);

          final completeUserData = Map<String, dynamic>.from(data);
          completeUserData['uid'] = credential.user!.uid;
          completeUserData['email'] = mockEmail;
          completeUserData['createdAt'] = FieldValue.serverTimestamp();
          completeUserData['updatedAt'] = FieldValue.serverTimestamp();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set(completeUserData);

          await FirebaseAuth.instance.signOut();
        }
        success++;
      } catch (e) {
        failed++;
        errors.add('ข้อผิดพลาด: ${e.toString()}');
      }
    }

    return {'success': success, 'failed': failed, 'errors': errors};
  }

  static Future<Map<String, dynamic>> _updateFirebaseDocument(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update(data);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static bool _isValidImportData(Map<String, dynamic> data) {
    // ตรวจสอบฟิลด์ที่จำเป็น
    if (data['idCard']?.toString().trim().isEmpty ?? true) return false;
    if (data['name']?.toString().trim().isEmpty ?? true) return false;
    if (data['phone']?.toString().trim().isEmpty ?? true) return false;
    if ((data['age'] as int?) == null || (data['age'] as int) <= 0) return false;
    
    // ตรวจสอบความยาวของเลขบัตรประชาชน
    if (data['idCard'].toString().length != 13) return false;
    
    // ตรวจสอบความยาวของเบอร์โทรศัพท์
    if (data['phone'].toString().length != 10) return false;
    
    return true;
  }
}

// ================= Data Models =================
class DownloadResult {
  final bool success;
  final String message;
  final String? filePath;
  final int totalRecords;

  DownloadResult({
    required this.success,
    required this.message,
    this.filePath,
    this.totalRecords = 0,
  });
}

class ImportResult {
  final bool success;
  final String message;
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.message,
    this.totalRows = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.errors = const [],
  });
}

class ImportDataItem {
  final Map<String, dynamic> data;
  final int rowNumber;
  final DuplicateInfo? duplicateInfo;
  final bool isValid;
  bool isSelected;
  ImportAction action;

  ImportDataItem({
    required this.data,
    required this.rowNumber,
    this.duplicateInfo,
    required this.isValid,
    this.isSelected = true,
    this.action = ImportAction.create,
  });
}

enum DuplicateType { idCard, phone }
enum ImportAction { create, update, skip }

class DuplicateInfo {
  final DuplicateType type;
  final Map<String, dynamic> existingData;
  final String docId;
  final String message;

  DuplicateInfo({
    required this.type,
    required this.existingData,
    required this.docId,
    required this.message,
  });
}

//================= Import Preview Dialog =================
class ImportPreviewDialog extends StatefulWidget {
  final List<ImportDataItem> importData;

  const ImportPreviewDialog({Key? key, required this.importData}) : super(key: key);

  @override
  _ImportPreviewDialogState createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> with TickerProviderStateMixin {
  late List<ImportDataItem> items;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    items = widget.importData;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ImportDataItem> get validItems => items.where((item) => item.isValid).toList();
  List<ImportDataItem> get duplicateItems => items.where((item) => !item.isValid).toList();
  List<ImportDataItem> get selectedItems => items.where((item) => item.isSelected).toList();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ตรวจสอบและแก้ไขข้อมูล',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
           
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: painting.Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                          color: _tabController.index == 0 ? const Color(0xFF10B981) : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text('ข้อมูลถูกต้อง (${validItems.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning,
                          color: _tabController.index == 1 ? Colors.orange : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text('ข้อมูลซ้ำ (${duplicateItems.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildValidDataTab(),
                  _buildDuplicateDataTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: painting.Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                children: [
                  Text('จะนำเข้า: ${selectedItems.length} รายการ'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectedItems.isEmpty ? null : _confirmImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text(
                      'นำเข้าข้อมูล',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidDataTab() {
    return ListView.builder(
      itemCount: validItems.length,
      itemBuilder: (context, index) {
        final item = validItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CheckboxListTile(
            value: item.isSelected,
            onChanged: (value) {
              setState(() => item.isSelected = value ?? false);
            },
            title: Text('แถว ${item.rowNumber}: ${item.data['name']}'),
            subtitle: Text('${item.data['idCard']} | ${item.data['phone']}'),
            secondary: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editItem(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuplicateDataTab() {
    return ListView.builder(
      itemCount: duplicateItems.length,
      itemBuilder: (context, index) {
        final item = duplicateItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: Checkbox(
              value: item.isSelected,
              onChanged: (value) {
                setState(() => item.isSelected = value ?? false);
              },
            ),
            title: Text('แถว ${item.rowNumber}: ${item.data['name']}'),
            subtitle: Text('${item.duplicateInfo!.message}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ข้อมูลใหม่:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('ชื่อ: ${item.data['name']}'),
                    Text('เบอร์: ${item.data['phone']}'),
                    const SizedBox(height: 8),
                    const Text('ข้อมูลเดิมในระบบ:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('ชื่อ: ${item.duplicateInfo!.existingData['name']}'),
                    Text('เบอร์: ${item.duplicateInfo!.existingData['phone']}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('การดำเนินการ: '),
                        DropdownButton<ImportAction>(
                          value: item.action,
                          onChanged: (action) {
                            setState(() {
                              item.action = action ?? ImportAction.skip;
                              item.isSelected = action != ImportAction.skip;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ImportAction.skip,
                              child: Text('ข้าม'),
                            ),
                            DropdownMenuItem(
                              value: ImportAction.update,
                              child: Text('อัพเดทข้อมูล'),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _editItem(item),
                          child: const Text('แก้ไข'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editItem(ImportDataItem item) {
    showDialog(
      context: context,
      builder: (context) => EditDataDialog(
        item: item,
        onSave: (updatedData) {
          setState(() {
            item.data.addAll(updatedData);
          });
        },
      ),
    );
  }

  void _confirmImport() {
    final dataToImport = <Map<String, dynamic>>[];
   
    for (final item in selectedItems) {
      if (item.action == ImportAction.update && item.duplicateInfo != null) {
        // For updates, we'll handle them separately in the service
        item.data['_updateDocId'] = item.duplicateInfo!.docId;
      }
      dataToImport.add(item.data);
    }
   
    Navigator.of(context).pop(dataToImport);
  }
}

// ================= Edit Data Dialog =================
class EditDataDialog extends StatefulWidget {
  final ImportDataItem item;
  final Function(Map<String, dynamic>) onSave;

  const EditDataDialog({
    Key? key,
    required this.item,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditDataDialogState createState() => _EditDataDialogState();
}

class _EditDataDialogState extends State<EditDataDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = {
      'name': TextEditingController(text: widget.item.data['name']?.toString() ?? ''),
      'idCard': TextEditingController(text: widget.item.data['idCard']?.toString() ?? ''),
      'phone': TextEditingController(text: widget.item.data['phone']?.toString() ?? ''),
      'age': TextEditingController(text: widget.item.data['age']?.toString() ?? ''),
      'address': TextEditingController(text: widget.item.data['address']?.toString() ?? ''),
      'weight': TextEditingController(text: widget.item.data['weight']?.toString() ?? ''),
      'height': TextEditingController(text: widget.item.data['height']?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'แก้ไขข้อมูล',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
             
              TextFormField(
                controller: controllers['name'],
                decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล *'),
                validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 8),
             
              TextFormField(
                controller: controllers['idCard'],
                decoration: const InputDecoration(labelText: 'เลขบัตรประชาชน *'),
                validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกเลขบัตร' : null,
              ),
              const SizedBox(height: 8),
             
              TextFormField(
                controller: controllers['phone'],
                decoration: const InputDecoration(labelText: 'เบอร์โทร *'),
                validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกเบอร์โทร' : null,
              ),
              const SizedBox(height: 8),
             
              TextFormField(
                controller: controllers['age'],
                decoration: const InputDecoration(labelText: 'อายุ *'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกอายุ' : null,
              ),
              const SizedBox(height: 8),
             
              TextFormField(
                controller: controllers['address'],
                decoration: const InputDecoration(labelText: 'ที่อยู่'),
              ),
              const SizedBox(height: 8),
             
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controllers['weight'],
                      decoration: const InputDecoration(labelText: 'น้ำหนัก (กก.)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controllers['height'],
                      decoration: const InputDecoration(labelText: 'ส่วนสูง (ซม.)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
             
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text(
                      'บันทึก',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedData = <String, dynamic>{};
     
      updatedData['name'] = controllers['name']!.text;
      updatedData['idCard'] = controllers['idCard']!.text.replaceAll(RegExp(r'[^0-9]'), '');
      updatedData['phone'] = controllers['phone']!.text.replaceAll(RegExp(r'[^0-9]'), '');
      updatedData['age'] = int.tryParse(controllers['age']!.text) ?? 0;
      updatedData['address'] = controllers['address']!.text;
     
      if (controllers['weight']!.text.isNotEmpty) {
        updatedData['weight'] = double.tryParse(controllers['weight']!.text);
      }
     
      if (controllers['height']!.text.isNotEmpty) {
        updatedData['height'] = double.tryParse(controllers['height']!.text);
      }
     
      // Calculate BMI if both weight and height are provided
      if (updatedData['weight'] != null && updatedData['height'] != null) {
        final h = updatedData['height'] as double;
        final w = updatedData['weight'] as double;
        if (h > 0 && w > 0) {
          updatedData['bmi'] = w / ((h / 100) * (h / 100));
        }
      }
     
      widget.onSave(updatedData);
      Navigator.of(context).pop();
    }
  }
}