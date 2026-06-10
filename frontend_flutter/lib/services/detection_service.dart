import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetectionService {
  static Future<List<dynamic>> detectObjects(File imageFile) async {
    final uri = Uri.parse("http://10.125.118.142:8000/detect"); // 👈 CHANGE PC_IP

    var request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody);
    } else {
      throw Exception("Detection failed with status ${response.statusCode}");
    }
  }
}
