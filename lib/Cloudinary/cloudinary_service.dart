import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:serategna/Cloudinary/cloudinary.dart';

Future<String?> uploadToCloudinary() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  if (result == null || result.files.single.path == null) return null;

  final file = File(result.files.single.path!);
  String cName = Cloudinary.cloudName;
  String pName = Cloudinary.presetName;

  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cName/image/upload');
  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = pName
    ..files.add(await http.MultipartFile.fromPath('file', file.path));

  final response = await request.send();
  final res = await http.Response.fromStream(response);
  final data = json.decode(res.body);

  if (response.statusCode == 200) {
    return data['secure_url'];
  } else {
    print("Upload failed: ${data['error']}");
    return null;
  }
}
