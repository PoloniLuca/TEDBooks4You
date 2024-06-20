import 'package:flutter/material.dart';
import 'models/book.dart';
import 'services/book_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BookListPage extends StatefulWidget {
  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final BookService _bookService = BookService();
  late Future<List<Book>> _books;

  @override
  void initState() {
    super.initState();
    _books = _bookService.fetchBooks();
  }

  String _shortenDescription(String description) {
    if (description.length > 100) {
      return description.substring(0, 100) + '...';
    } else {
      return description;
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $url');
    }
  }

  void _showBookDetails(Book book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                book.thumbnail != null
                    ? Image.network(
                        book.thumbnail!,
                        width: 100,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.book, size: 100),
                SizedBox(height: 10),
                Text(
                  book.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text('Author: ${book.authors ?? "Unknown"}'),
                SizedBox(height: 10),
                Text(book.description ?? 'No description available'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _launchURL(book.link),
                  child: Text('Buy Book'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book List'),
      ),
      body: FutureBuilder<List<Book>>(
        future: _books,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No books available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final book = snapshot.data![index];
                return GestureDetector(
                  onTap: () => _showBookDetails(book),
                  child: Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      leading: book.thumbnail != null
                          ? Image.network(
                              book.thumbnail!,
                              width: 80,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.book, size: 80),
                      title: Text(
                        book.title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          book.description != null
                              ? Text(_shortenDescription(book.description!))
                              : Text('No description available'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
