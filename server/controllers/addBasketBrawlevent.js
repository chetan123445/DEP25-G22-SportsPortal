import BasketBrawlevent from '../models/BasketBrawlevent.js';
import Team from '../models/Team.js';

export const addBasketBrawlevent = async (req, res) => {
    try {
        const { gender, eventType, type, date, time, venue, description, winner, team1, team2, team1Details, team2Details, eventManagers } = req.body;

        // Validate required fields
        if (!gender || !eventType || !type || !date || !time || !venue || !team1 || !team2) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        // Create team1 if details are provided
        let team1Doc = null;
        if (team1Details && team1Details.members && team1Details.members.length > 0) {
            const newTeam1 = new Team({
                teamName: team1Details.teamName,
                members: team1Details.members
            });
            team1Doc = await newTeam1.save();
        }

        // Create team2 if details are provided
        let team2Doc = null;
        if (team2Details && team2Details.members && team2Details.members.length > 0) {
            const newTeam2 = new Team({
                teamName: team2Details.teamName,
                members: team2Details.members
            });
            team2Doc = await newTeam2.save();
        }

        // Prepare event managers array
        const eventManagersArray = Array.isArray(eventManagers) ? eventManagers : [];

        const newEvent = new BasketBrawlevent({
            gender,
            eventType,
            type,
            date,
            time,
            venue,
            description,
            winner,
            team1,
            team2,
            team1Details: team1Doc ? team1Doc._id : null,
            team2Details: team2Doc ? team2Doc._id : null,
            eventManagers: eventManagersArray
        });

        await newEvent.save();
        res.status(201).json({ message: 'Event added successfully', event: newEvent });
    } catch (error) {
        console.error('Error in addBasketBrawlevent:', error); // Add this debug line
        res.status(500).json({ message: 'Error adding event', error: error.message });
    }
};
