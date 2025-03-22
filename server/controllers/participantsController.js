import GCevent from '../models/GCevent.js';
import Team from '../models/Team.js';

export const getEventParticipants = async (req, res) => {
    try {
        const { eventId } = req.params;

        if (!eventId) {
            return res.status(400).json({ message: 'Event ID is required' });
        }

        console.log(`Fetching participants for event ID: ${eventId}`);
        const event = await GCevent.findById(eventId).exec();

        if (!event) {
            console.log(`Event not found for ID: ${eventId}`);
            return res.status(404).json({ message: 'Event not found' });
        }

        const teamIds = event.participants; // Array of ObjectIDs representing teams
        if (!teamIds || teamIds.length === 0) {
            return res.status(200).json({ participants: [] }); // No participants
        }

        // Fetch all teams and their members using the team IDs
        const teams = await Team.find({ _id: { $in: teamIds } }).exec();

        const participants = teams.map(team => ({
            teamName: team.teamName,
            members: team.members.map(member => ({
                name: member.name,
                email: member.email
            }))
        }));

        res.status(200).json({ participants });
    } catch (error) {
        console.error(`Error fetching participants for event ID: ${eventId}`, error);
        res.status(500).json({ message: 'Error fetching participants', error });
    }
};
