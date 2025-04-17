import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'PlayerProfilePage.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GCEventDetailsPage extends StatefulWidget {
  final dynamic event;
  final bool isReadOnly;

  GCEventDetailsPage({required this.event, this.isReadOnly = false});

  @override
  _GCEventDetailsPageState createState() => _GCEventDetailsPageState();
}

class _GCEventDetailsPageState extends State<GCEventDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> commentary = [];
  TextEditingController _commentaryController = TextEditingController();
  bool isMatchLive = false;
  String matchStatus = 'Not Started';
  late IO.Socket socket;
  bool _isBlinking = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _tabController = TabController(length: 1, vsync: this);
    fetchEventDetails();
    checkMatchStatus();
    connectToSocket();

    // Add listener for when page gets focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.addListener(() {
        if (_focusNode.hasFocus) {
          fetchEventDetails();
        }
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    socket.disconnect();
    _tabController.dispose();
    super.dispose();
  }

  void connectToSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.emit('join-event', widget.event['_id']);

    socket.on('commentary-update', handleCommentaryUpdate);
  }

  void handleCommentaryUpdate(dynamic data) {
    if (data['eventId'] == widget.event['_id'] && mounted) {
      setState(() {
        if (data['type'] == 'add') {
          commentary.insert(0, {
            'id': data['newComment']['id'],
            'text': data['newComment']['text'],
            'timestamp': data['newComment']['timestamp'],
          });
        } else if (data['type'] == 'delete') {
          commentary.removeWhere((c) => c['id'] == data['commentaryId']);
        }
      });
    }
  }

  Future<void> fetchEventDetails() async {
    try {
      print(
        'Fetching event details for ID: ${widget.event['_id']}',
      ); // Debug log

      final response = await http.get(
        Uri.parse('$baseUrl/gc/event/${widget.event['_id']}'),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['event'] != null) {
          setState(() {
            commentary = List<Map<String, dynamic>>.from(
              (data['event']['commentary'] ?? []).map(
                (c) => {
                  'id': c['_id'] ?? '',
                  'text': c['text'] ?? '',
                  'timestamp':
                      c['timestamp'] ?? DateTime.now().toIso8601String(),
                },
              ),
            );

            commentary.sort(
              (a, b) => DateTime.parse(
                b['timestamp'],
              ).compareTo(DateTime.parse(a['timestamp'])),
            );
          });
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load event data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching event details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading event details: $e')),
        );
      }
    }
  }

  Future<void> checkMatchStatus() async {
    final eventDate = DateTime.parse(widget.event['date']);
    final now = DateTime.now();
    setState(() {
      isMatchLive =
          eventDate.year == now.year &&
          eventDate.month == now.month &&
          eventDate.day == now.day;
      matchStatus =
          isMatchLive
              ? 'Live'
              : eventDate.isBefore(now)
              ? 'Completed'
              : 'Not Started Yet';
    });
  }

  Future<void> addCommentary(String text) async {
    if (text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gc/add-commentary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _commentaryController.clear();
        // Let socket event handle the update
      } else {
        throw Exception('Failed to add commentary');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding commentary: $e')));
    }
  }

  Future<void> deleteCommentary(String commentaryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gc/delete-commentary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'commentaryId': commentaryId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete commentary');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting commentary: $e')));
    }
  }

  Widget _buildCommentaryTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade100, Colors.grey.shade200],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black87,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Live Commentary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: commentary.length,
              itemBuilder: (context, index) {
                final comment = commentary[index];
                final commentTime = DateTime.parse(comment['timestamp']);
                final formattedTime = DateFormat('HH:mm').format(commentTime);
                final formattedDate = DateFormat('MMM dd').format(commentTime);
                final isCurrentDate = commentTime.day == DateTime.now().day;

                return Dismissible(
                  key: Key(comment['id']),
                  direction:
                      !widget.isReadOnly
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                  onDismissed: (_) => deleteCommentary(comment['id']),
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.black87,
                      child: InkWell(
                        onTap: () {
                          final fullDateTime = DateFormat(
                            'EEEE, MMMM d, y\nh:mm a',
                          ).format(commentTime);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(fullDateTime),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.black,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color:
                                  isCurrentDate
                                      ? Colors.blue.shade400
                                      : Colors.grey.shade600,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isCurrentDate
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade700,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$formattedDate at $formattedTime',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (!widget.isReadOnly)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red.shade300,
                                      ),
                                      onPressed:
                                          () => deleteCommentary(comment['id']),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                comment['text'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.3,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isMatchLive && !widget.isReadOnly)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentaryController,
                      decoration: InputDecoration(
                        hintText: 'Add commentary...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (text) => addCommentary(text),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => addCommentary(_commentaryController.text),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        appBar: AppBar(
          title: Text('GC Match Details'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade200,
                  Colors.blue.shade200,
                  Colors.pink.shade100,
                ],
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [Tab(icon: Icon(Icons.comment), text: 'Commentary')],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildCommentaryTab()],
        ),
      ),
    );
  }
}
