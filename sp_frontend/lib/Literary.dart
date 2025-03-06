import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome package
import 'Cultural.dart';
class GCPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 79, 188, 247), Color.fromARGB(255, 142, 117, 205)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'GC Events',
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          children: [
            _buildEventCard(context, FontAwesomeIcons.gamepad, 'General Quiz'), // eSports icon
            _buildEventCard(context, FontAwesomeIcons.masksTheater, 'Poetry Slam'), // Cultural icon
            _buildEventCard(context, FontAwesomeIcons.microchip, 'Speech'), // Technical icon
            _buildEventCard(context, FontAwesomeIcons.bookOpen, 'Debate'), // Literary icon
            _buildEventCard(context, FontAwesomeIcons.futbol, 'Essay Writing'), // Sports icon
            _buildEventCard(context, FontAwesomeIcons.personWalking, 'Film Making'), // Dance icon
            _buildEventCard(context, FontAwesomeIcons.microphone, 'Singing'), // Singing icon
            _buildEventCard(context, FontAwesomeIcons.dumbbell, 'Weightlifting'), // Weightlifting icon
            _buildEventCard(context, FontAwesomeIcons.weight, 'Powerlifting'), // Powerlifting icon
            _buildEventCard(context, FontAwesomeIcons.chess, 'Chess'), // Chess icon
            _buildEventCard(context, FontAwesomeIcons.handRock, 'Tug of War'), // Tug of War icon
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
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
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}