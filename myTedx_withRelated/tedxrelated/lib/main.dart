import 'package:flutter/material.dart';
import 'talk_repository.dart';
import 'models/talk.dart';
import 'video_details_page.dart'; // Assicurati di avere l'importazione giusta

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTEDx',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    this.title = 'MyTEDx',
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<Talk>> _talks;
  int page = 1;
  bool init = true;

  @override
  void initState() {
    super.initState();
    _talks = initEmptyList();
    init = true;
  }

  void _getTalksByTag() async {
    setState(() {
      init = false;
      _talks = getTalksByTag(_controller.text, page);
    });
  }

  void _showDescriptionDialog(BuildContext context, Talk talk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(talk.title),
          content: Text(talk.details),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TedBooks4You - first part',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TedBooks4You - first part'),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: (init)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                          hintText: 'Enter your favorite talk'),
                    ),
                    ElevatedButton(
                      child: const Text('Search by tag'),
                      onPressed: () {
                        page = 1;
                        _getTalksByTag();
                      },
                    ),
                  ],
                )
              : FutureBuilder<List<Talk>>(
                  future: _talks,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Scaffold(
                        appBar: AppBar(
                          title: Text("#${_controller.text}"),
                        ),
                        body: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: GestureDetector(
                                onTap: () {
                                  _showDescriptionDialog(context, snapshot.data![index]);
                                },
                                child: Text(snapshot.data![index].title),
                              ),
                              subtitle: Text(snapshot.data![index].mainSpeaker),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.video_library,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoDetailsPage(
                                        videoId: snapshot.data![index].id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        floatingActionButtonLocation:
                            FloatingActionButtonLocation.centerDocked,
                        floatingActionButton: FloatingActionButton(
                          child: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            if (snapshot.data!.length >= 6) {
                              page = page + 1;
                              _getTalksByTag();
                            }
                          },
                        ),
                        bottomNavigationBar: BottomAppBar(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.home),
                                onPressed: () {
                                  setState(() {
                                    init = true;
                                    page = 1;
                                    _controller.text = "";
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    }

                    return const CircularProgressIndicator();
                  },
                ),
        ),
      ),
    );
  }
}
