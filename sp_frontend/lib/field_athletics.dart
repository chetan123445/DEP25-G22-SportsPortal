import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome package

class FieldAthleticsPage extends StatefulWidget {
  @override
  _FieldAthleticsPageState createState() => _FieldAthleticsPageState();
}

class _FieldAthleticsPageState extends State<FieldAthleticsPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final events = [
      {'icon': FontAwesomeIcons.running, 'title': 'Race'},
      {'icon': FontAwesomeIcons.circle, 'title': 'Shot Put'},
      {'icon': FontAwesomeIcons.compactDisc, 'title': 'Discus Throw'},
      {'icon': FontAwesomeIcons.arrowUp, 'title': 'Javelin Throw'},
      {'icon': FontAwesomeIcons.running, 'title': 'Long Jump'},
      {'icon': FontAwesomeIcons.running, 'title': 'High Jump'},
    ];

    final filteredEvents =
        events
            .where(
              (event) => (event['title'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 79, 188, 247),
                Color.fromARGB(255, 142, 117, 205),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'Field Athletics Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your Sport',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  filteredEvents.isEmpty
                      ? Center(
                        child: Text(
                          'No such sport found',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        children:
                            filteredEvents.map((event) {
                              return _buildEventCard(
                                context,
                                event['icon'] as IconData,
                                event['title'] as String,
                              );
                            }).toList(),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        // Handle event tap
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(16.0),
                child: Icon(icon, size: 48.0, color: Colors.black),
              ),
              SizedBox(height: 8.0),
              Text(
                title,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
