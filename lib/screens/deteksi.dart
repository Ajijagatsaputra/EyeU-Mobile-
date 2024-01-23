import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeteksiPage extends StatefulWidget {
  const DeteksiPage({Key? key}) : super(key: key);

  @override
  _DeteksiPageState createState() => _DeteksiPageState();
}

class _DeteksiPageState extends State<DeteksiPage> {
  File? _file;
  String? predictionResult = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deteksi Kesehatan Mata',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.blue],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildImagePreview(),
                const SizedBox(height: 16),
                _buildPredictionText(),
                const SizedBox(height: 16),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return _file == null
        ? Container(
            height: 200,
            width: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.photo,
                size: 50,
                color: Colors.grey,
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _file!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          );
  }

  Widget _buildPredictionText() {
    String formattedPrediction = _formatPrediction(predictionResult);

    return Text(
      formattedPrediction,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.white,
      ),
    );
  }

  String _formatPrediction(String? jsonPrediction) {
    if (jsonPrediction == null) {
      return "Tidak ada prediksi";
    }

    try {
      Map<String, dynamic> predictionMap = jsonDecode(jsonPrediction);
      String result = predictionMap["result"];
      return "Prediksi: $result";
    } catch (e) {
      return "Format prediksi tidak valid";
    }
  }

  Widget _buildButtons() {
    return Column(
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: () => _pickImage(),
          icon: const Icon(FontAwesomeIcons.upload),
          label: const Text("Upload Gambar"),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            await _uploadAndPredict();
            print("Hasil Prediksi: $predictionResult");
            // Tampilkan hasil prediksi setelah proses prediksi selesai
            _showPredictionResultDialog();
          },
          icon: const Icon(FontAwesomeIcons.wandMagic),
          label: const Text("Deteksi"),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadAndPredict() async {
    if (_file == null) {
      print("Pilih gambar terlebih dahulu");
      return;
    }

    String uploadResult = await uploadImage(_file!);
    print("Upload Result: $uploadResult");

    // Include logic for image processing and prediction here
    String predictionResult = await _processAndPredict(_file!);

    setState(() {
      this.predictionResult = predictionResult;
    });

    print("Prediction Result: $predictionResult");
  }

  Future<String> _processAndPredict(File imageFile) async {
  try {
    var uri = Uri.parse("https://b5c8-103-166-147-253.ngrok-free.app/api/deteksi");

    var request = http.MultipartRequest("POST", uri);
    var multipartFile = http.MultipartFile(
      'file',
      http.ByteStream(Stream.castFrom(imageFile.openRead())),
      imageFile.lengthSync(),
      filename: imageFile.path.split("/").last,
      contentType: MediaType('image', 'jpeg'),
    );

    request.files.add(multipartFile);

    var response = await request.send();
    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      Map<String, dynamic> result = jsonDecode(responseBody);

      // Mendapatkan hasil prediksi dari respons API
      String predictedClass = result['result'];

      return "Prediksi: $predictedClass";
    } else {
      return "Gagal mendapatkan hasil prediksi.";
    }
  } catch (e) {
    return "Error menghubungi server: $e";
  }
}


  Future<String> uploadImage(File imageFile) async {
    try {
      var uri = Uri.parse("https://b5c8-103-166-147-253.ngrok-free.app/uploadFileAndroid");

      var request = http.MultipartRequest("POST", uri);
      var multipartFile = http.MultipartFile(
        'file',
        http.ByteStream(Stream.castFrom(imageFile.openRead())),
        imageFile.lengthSync(),
        filename: imageFile.path.split("/").last,
        contentType: MediaType('image', 'jpeg'), // Specify the content type
      );

      request.files.add(multipartFile);

      var response = await request.send();
      if (response.statusCode == 200) {
        return "File uploaded successfully";
      } else {
        return "Image upload failed.";
      }
    } catch (e) {
      return "Error uploading image: $e";
    }
  }

  // Metode untuk menampilkan hasil prediksi dalam bentuk dialog
  Future<void> _showPredictionResultDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hasil Prediksi'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Hasil Prediksi:'),
                Text(predictionResult ?? 'Tidak ada prediksi'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: DeteksiPage(),
  ));
}
