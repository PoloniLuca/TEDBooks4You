// services/book_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookService {
  final String apiUrl = 'https://u9kzhlg3ee.execute-api.us-east-1.amazonaws.com/default/getBooksByIDutente_cronologia';

  Future<List<Book>> fetchBooks() async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'id': '664473f96edd176315934c90',
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['books'];
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}
