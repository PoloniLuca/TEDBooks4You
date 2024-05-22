import 'package:flutter/material.dart';
import 'talk_repository.dart';
import 'models/talk.dart';

class VideoDetailsPage extends StatelessWidget {
  final String videoId;

  const VideoDetailsPage({super.key, required this.videoId});

  Future<List<Talk>> _fetchRelatedVideos(List<String> relatedVideoIds) async {
    List<Talk> relatedVideos = [];
    for (String id in relatedVideoIds) {
      if (id.isEmpty) {
        print('Skipping empty related video ID');
        continue;
      }
      try {
        Talk talk = await getVideoById(id);
        relatedVideos.add(talk);
      } catch (e) {
        print('Failed to load related video with id: $id, error: $e');
      }
    }
    return relatedVideos;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Related Videos'),
      ),
      body: FutureBuilder<Talk>(
        future: getVideoById(videoId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Talk talk = snapshot.data!;
            return FutureBuilder<List<Talk>>(
              future: _fetchRelatedVideos(talk.relatedVideos),
              builder: (context, relatedSnapshot) {
                if (relatedSnapshot.hasData) {
                  List<Talk> relatedVideos = relatedSnapshot.data!;
                  return ListView.builder(
                    itemCount: relatedVideos.length,
                    itemBuilder: (context, index) {
                      Talk relatedTalk = relatedVideos[index];
                      return ListTile(
                        title: GestureDetector(
                          onTap: () {
                            _showDescriptionDialog(context, relatedTalk);
                          },
                          child: Text(relatedTalk.title),
                        ),
                        subtitle: Text(relatedTalk.mainSpeaker),
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
                                  videoId: relatedTalk.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                } else if (relatedSnapshot.hasError) {
                  return Text(
                      "Error loading related videos: ${relatedSnapshot.error}");
                }
                return const CircularProgressIndicator();
              },
            );
          } else if (snapshot.hasError) {
            return Text("Error loading video details: ${snapshot.error}");
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
