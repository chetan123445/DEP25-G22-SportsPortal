class TeamMember {
  String name;
  String email;
  String? userId;

  TeamMember({required this.name, required this.email, this.userId});
}

class Team {
  String teamName;
  List<TeamMember> members;

  Team({required this.teamName, required this.members});
}

class Event {
  String gender;
  String? mainType;
  String eventType;
  String type;
  DateTime date;
  String time;
  String venue;
  String? description;
  String? winner;
  String team1;
  String team2;
  Team? team1Details;
  Team? team2Details;

  Event({
    required this.gender,
    this.mainType,
    required this.eventType,
    required this.type,
    required this.date,
    required this.time,
    required this.venue,
    this.description,
    this.winner,
    required this.team1,
    required this.team2,
    this.team1Details,
    this.team2Details,
  });
}
