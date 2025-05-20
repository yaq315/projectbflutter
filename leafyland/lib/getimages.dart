import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageGallery extends StatefulWidget {
  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    fetchImage();
  }

  // Fetch single image from the API
  Future<void> fetchImage() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/products/2'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        imageUrl = data['data']['image'];
      });
    } else {
      print('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Gallery')),
      body: imageUrl != null
          ? Center(
              child: Image.network(imageUrl!),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
