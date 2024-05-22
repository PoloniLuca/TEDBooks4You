import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/talk.dart';

Future<List<Talk>> initEmptyList() async {
  return [];
}

Future<List<Talk>> getTalksByTag(String tag, int page) async {
  var url = Uri.parse('https://8o06k5q39h.execute-api.us-east-1.amazonaws.com/default/getTalksByTag');

  final http.Response response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, Object>{
      'tag': tag,
      'page': page,
      'doc_per_page': 6,
    }),
  );
  if (response.statusCode == 200) {
    Iterable list = json.decode(response.body);
    var talks = list.map((model) => Talk.fromJSON(model)).toList();
    return talks;
  } else {
    throw Exception('Failed to load talks');
  }
}



Future<Talk> getVideoById(String id) async {
  if (id.isEmpty) {
    throw Exception('Video ID cannot be null or empty');
  }

  var url = Uri.parse('https://gmdefeh0da.execute-api.us-east-1.amazonaws.com/default/getVideosById');

  final http.Response response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, Object>{
      'id': id,
    }),
  );

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    try {
      var jsonList = jsonDecode(response.body) as List;
      if (jsonList.isEmpty) {
        throw Exception('No video details found');
      }
      var json = jsonList.first as Map<String, dynamic>;
      return Talk.fromJSON(json);
    } catch (e) {
      print('Error parsing JSON: $e');
      throw Exception('Failed to parse video details');
    }
  } else {
    print('Failed to load video details: ${response.reasonPhrase}');
    throw Exception('Failed to load video details');
  }
}
