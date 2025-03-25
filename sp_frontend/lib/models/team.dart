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