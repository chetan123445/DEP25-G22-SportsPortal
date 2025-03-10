import IYSCevent from '../models/IYSCevent.js';

export const addIYSCevent = async (req, res) => {
    try {
        const { gender, type, date, time, venue, description, winner, team1, team2 } = req.body;
        const newEvent = new IYSCevent({ gender, type, date, time, venue, description: description || null, winner: winner || null , team1, team2});
        await newEvent.save();
        res.status(201).json({ message: 'Event added successfully', event: newEvent });
    } catch (error) {
        res.status(500).json({ message: 'Error adding event', error });
    }
};
