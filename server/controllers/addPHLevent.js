import PHLevent from '../models/PHLevent.js';
import Team from '../models/Team.js';

export const addPHLevent = async (req, res) => {
    try {
        const { gender, type, date, time, venue, description, winner, team1, team2, team1Details, team2Details } = req.body;

        // Validate required fields
        if (!gender || !type || !date || !time || !venue || !team1 || !team2) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        // Create team1 if details are provided
        let team1Doc = null;
        if (team1Details) {
            const newTeam1 = new Team(team1Details);
            team1Doc = await newTeam1.save();
        }

        // Create team2 if details are provided
        let team2Doc = null;
        if (team2Details) {
            const newTeam2 = new Team(team2Details);
            team2Doc = await newTeam2.save();
        }

        const newEvent = new PHLevent({
            gender,
            type,
            date,
            time,
            venue,
            description,
            winner,
            team1,
            team2,
            team1Details: team1Doc ? team1Doc._id : null,
            team2Details: team2Doc ? team2Doc._id : null
        });

        await newEvent.save();
        res.status(201).json({ message: 'Event added successfully', event: newEvent });
    } catch (error) {
        res.status(500).json({ message: 'Error adding event', error });
    }
};
