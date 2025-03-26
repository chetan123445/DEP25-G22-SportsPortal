import Event from '../models/Event.js'; // Ensure this path is correct
import Team from '../models/Team.js'; // Import the Team model

// Fetch all players with their names and emails
export const getAllPlayersWithDetails = async (req, res) => {
  try {
    const events = await Event.find({}, 'eventType team1Details team2Details participants'); // Fetch relevant fields
    const playersWithDetails = [];

    for (const event of events) {
      const { eventType, team1Details, team2Details, participants } = event;

      // Fetch players from team1Details and team2Details for specific event types
      if (['IYSC', 'IRCC', 'BasketBrawl', 'PHL'].includes(eventType)) {
        if (team1Details) {
          const team1 = await Team.findById(team1Details, 'members');
          if (team1) {
            team1.members.forEach(member => {
              playersWithDetails.push({
                name: member.name,
                email: member.email,
                eventType,
              });
            });
          }
        }

        if (team2Details) {
          const team2 = await Team.findById(team2Details, 'members');
          if (team2) {
            team2.members.forEach(member => {
              playersWithDetails.push({
                name: member.name,
                email: member.email,
                eventType,
              });
            });
          }
        }
      }

      // Fetch participants for GC events
      if (eventType === 'GC' && participants) {
        participants.forEach(participant => {
          playersWithDetails.push({
            name: participant.name,
            email: participant.email,
            eventType,
          });
        });
      }
    }

    res.status(200).json(playersWithDetails);
  } catch (error) {
    console.error('Error fetching players with details:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Fetch all players from all teams
export const getAllPlayersFromTeams = async (req, res) => {
  try {
    const teams = await Team.find({}, 'teamName members'); // Fetch teamName and members fields only
    const playersWithDetails = [];

    teams.forEach(team => {
      team.members.forEach(member => {
        playersWithDetails.push({
          name: member.name,
          email: member.email,
          teamName: team.teamName, // Include the team name for reference
        });
      });
    });

    res.status(200).json(playersWithDetails);
  } catch (error) {
    console.error('Error fetching players from teams:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
