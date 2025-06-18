import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:serategna/Cloudinary/cloudinary.dart';

class CloudinaryService {
  static const String cloudName = Cloudinary.cloudName;
  static const String uploadPreset = Cloudinary.presetName;

  /// Pick image, fix rotation, upload to Cloudinary, and return URL
  static Future<String?> uploadToCloudinary(XFile picked) async {
    
    //if (picked == null) return null;

    final originalFile = File(picked.path);
    final fixedFile = await _fixImageRotation(originalFile);

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', fixedFile.path));

    final response = await request.send();
    final res = await http.Response.fromStream(response);
    final data = json.decode(res.body);

    if (response.statusCode == 200 && data['secure_url'] != null) {
      return data['secure_url'];
    } else {
      print('Upload failed: ${data['error']}');
      return null;
    }
  }

  /// Fix image rotation using EXIF data
  static Future<File> _fixImageRotation(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception("Unable to decode image");

    final fixed = img.bakeOrientation(decoded);
    final fixedBytes = Uint8List.fromList(img.encodeJpg(fixed, quality: 90));
    final newPath =
        '${file.parent.path}/fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fixedFile = File(newPath);
    return await fixedFile.writeAsBytes(fixedBytes);
  }



static Future<String?> uploadCVToCloudinary(String filePath) async {

  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');

  var request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..fields['folder'] = 'cvs' // optional folder
    ..files.add(await http.MultipartFile.fromPath('file', filePath));

  final response = await request.send();

  if (response.statusCode == 200) {
    final respData = await response.stream.bytesToString();
    final jsonResp = json.decode(respData);
    return jsonResp['secure_url']; // your CV URL
  } else {
    final error = await response.stream.bytesToString();
    log("Cloudinary upload failed: $error");
    return null;
  }
}



}
