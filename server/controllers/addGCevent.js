import GCevent from '../models/GCevent.js';
import Team from '../models/Team.js';

export async function addGCEvent(req, res) {
    try {
        const { MainType, eventType, type, gender, date, time, venue, description, winner, participants, eventManagers,commentary = [] } = req.body;

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
            eventManagers: eventManagers || [], // Each manager in array should have {name, email}
            commentary // Add commentary array to new event
        });

        await newGCevent.save();
        res.status(201).json({ message: 'GC event created successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Failed to add GC event', error });
    }
};

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
};

export const addMatchCommentary = async (req, res) => {
    try {
        const { eventId, text, timestamp } = req.body;
        const event = await GCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const newCommentary = { text, timestamp };
        event.commentary = [newCommentary, ...event.commentary]; // Add to start of array
        await event.save();

        const addedCommentary = event.commentary[0]; // Get the first (newest) commentary
        
        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('commentary-update', {
                eventId,
                newComment: {
                    id: addedCommentary._id,
                    text: addedCommentary.text,
                    timestamp: addedCommentary.timestamp
                },
                type: 'add'
            });
        }

        res.status(200).json({ 
            message: 'Commentary added successfully', 
            commentary: addedCommentary 
        });
    } catch (error) {
        console.error('Error adding commentary:', error);
        res.status(500).json({ message: 'Error adding commentary', error: error.message });
    }
};

export const deleteCommentary = async (req, res) => {
    try {
        const { eventId, commentaryId } = req.body;
        const event = await GCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        event.commentary = event.commentary.filter(
            comment => comment._id.toString() !== commentaryId
        );
        await event.save();

        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('commentary-update', {
                eventId,
                type: 'delete',
                commentaryId: commentaryId
            });
        }
        
        res.status(200).json({ 
            message: 'Commentary deleted successfully', 
            commentaryId 
        });
    } catch (error) {
        console.error('Error deleting commentary:', error);
        res.status(500).json({ message: 'Error deleting commentary', error: error.message });
    }
};

export const getEventDetails = async (req, res) => {
    try {
        const eventId = req.params.id; // Change from req.query to req.params
        console.log('Fetching event with ID:', eventId);
        
        const event = await GCevent.findById(eventId);
        
        if (!event) {
            console.log('Event not found for ID:', eventId);
            return res.status(404).json({ message: 'Event not found' });
        }

        console.log('Event found:', event);
        res.status(200).json({ 
            event: event 
        });
    } catch (error) {
        console.error('Error fetching event details:', error);
        res.status(500).json({ message: 'Error fetching event details', error: error.message });
    }
};