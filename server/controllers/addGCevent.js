import GCevent from '../models/GCevent.js';
import Team from '../models/Team.js';

export async function addGCEvent(req, res) {
    try {
        const { MainType, eventType, type, gender, date, time, venue, description, winner, participants, eventManagers } = req.body;

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
            participants: teamIds,
            eventManagers: eventManagers || [] // Each manager in array should have {name, email}
        });

        await newGCevent.save();
        res.status(201).json({ message: 'GC event created successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Failed to add GC event', error });
    }
}

export async function getGCEventsByMainType(req, res) {
    try {
        const { MainType } = req.query;
        console.log('Received request for MainType:', MainType);

        if (!MainType) {
            return res.status(400).json({ message: 'MainType parameter is required' });
        }

        // Case-insensitive search for MainType
        const events = await GCevent.find({
            MainType: { $regex: new RegExp('^' + MainType + '$', 'i') }
        }).populate('participants');

        console.log(`Found ${events.length} events for MainType: ${MainType}`);
        
        return res.status(200).json({ 
            success: true,
            data: events 
        });
    } catch (error) {
        console.error('Error in getGCEventsByMainType:', error);
        return res.status(500).json({ 
            success: false, 
            message: 'Failed to fetch GC events',
            error: error.message 
        });
    }
}
