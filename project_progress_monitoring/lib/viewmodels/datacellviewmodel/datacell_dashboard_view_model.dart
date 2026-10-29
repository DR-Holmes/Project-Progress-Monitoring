import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../view/login_view.dart';

class DatacellDashboardViewModel {
  // Pick an excel file from the device
  Future<PlatformFile?> pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Crucial for getting bytes on all platforms
      );

      if (result != null && result.files.single.bytes != null) {
        return result.files.single;
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
    return null;
  }

  // Parse Excel file bytes and return a list of rows for preview
  List<Map<String, String>> parseExcelForPreview(Uint8List bytes, String type) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, String>> previewData = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 1) continue;

      // Assuming first row is header
      var headers = sheet.rows[0].map((e) => e?.value?.toString() ?? "").toList();

      // Show up to 5-10 rows for preview
      int rowLimit = sheet.maxRows > 11 ? 11 : sheet.maxRows;

      for (int i = 1; i < rowLimit; i++) {
        Map<String, String> rowMap = {};
        for (int j = 0; j < headers.length; j++) {
          if (j < sheet.rows[i].length) {
            rowMap[headers[j]] = sheet.rows[i][j]?.value?.toString() ?? "";
          }
        }
        previewData.add(rowMap);
      }
      break; // Only parse the first sheet
    }
    return previewData;
  }

  // Upload the file to the backend
  Future<Map<String, dynamic>> uploadExcel(Uint8List bytes, String fileName, String type) async {
    try {
      String endpoint = type == "Student" ? "UploadStudentsData" : "UploadUsersExcel";
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/auth/$endpoint"),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {"success": true, "message": jsonDecode(response.body)['Message'] ?? "Upload successful"};
      } else {
        String errorMsg = "Upload failed";
        try {
          var body = jsonDecode(response.body);
          errorMsg = body['Message'] ?? body['error'] ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }
        return {"success": false, "message": errorMsg};
      }
    } catch (e) {
      debugPrint("Error uploading file: $e");
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  void logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  // Create and download a sample excel file
  Future<void> downloadSample(String type) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      List<String> headers;
      List<String> sampleRow;

      if (type == "Student") {
        headers = ['regNum', 'name', 'email', 'gender', 'cgpa', 'admissionSession', 'department', 'section', 'password', 'subject', 'session', 'grade', 'semesterNo'];
        sampleRow = ['2021-CS-001', 'Ali', 'ali@test.com', 'M', '3.5', '2021', 'CS', 'A', 'pass123', 'FYP-1', '1', 'A', '7'];
      } else {
        headers = ['id', 'name', 'password', 'email', 'role'];
        sampleRow = ['EMP01', 'Ahmed', 'pass123', 'ahmed@test.com', 'Teacher'];
      }

      // Append headers
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());
      // Append sample data
      sheetObject.appendRow(sampleRow.map((e) => TextCellValue(e)).toList());

      // Save file dialog
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: '${type.toLowerCase()}_sample.xlsx',
      );

      if (outputFile != null) {
        var fileBytes = excel.save();
        if (fileBytes != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
        }
      }
    } catch (e) {
      debugPrint("Error downloading sample: $e");
    }
  }
}