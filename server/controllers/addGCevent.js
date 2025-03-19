import GCevent from '../models/GCevent.js';
import Team from '../models/Team.js';

export async function addGCEvent(req, res) {
    try {
        const { MainType,eventType, type, gender, date, time, venue, description, winner, participants } = req.body;

        // Validate required fields
        if (!MainType || !eventType || !type || !date || !time || !venue) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        let teamIds = [];
        if (participants && participants.length > 0) {
            // Create teams with members
            teamIds = await Promise.all(participants.map(async (team) => {
                const newTeam = new Team({
                    teamName: team.teamName,
                    members: team.members // Directly use the members array
                });

                await newTeam.save();
                return newTeam._id;
            }));
        }

        // Create GC event
        const newGCevent = new GCevent({
            MainType,
            eventType,
            type,
            gender, // Include gender attribute
            date,
            time,
            venue,
            description,
            winner,
            participants: teamIds
        });

        await newGCevent.save();
        res.status(201).json({ message: 'GC event created successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Failed to add GC event', error });
    }
}
