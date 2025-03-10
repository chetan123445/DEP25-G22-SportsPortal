import IYSCevent from '../models/IYSCevent.js';

export const addIYSCevent = async (req, res) => {
    try {
        const { gender, type, date, time, venue, description, winner } = req.body;
        const newEvent = new IYSCevent({ gender, type, date, time, venue, description, winner: winner || null });
        await newEvent.save();
        res.status(201).json({ message: 'Event added successfully', event: newEvent });
    } catch (error) {
        res.status(500).json({ message: 'Error adding event', error });
    }
};
