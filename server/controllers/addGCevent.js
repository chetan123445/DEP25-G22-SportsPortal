import GCevent from '../models/GCevent.js'; // Import the GCevent model

export const addGCevent = async (req, res) => {
    const { MainType, type, date } = req.body; // Include date in destructuring

    if (!MainType || !type || !date) { // Check for date
        return res.status(400).json({ message: "MainType, type, and date are required" });
    }

    try {
        const newGCevent = new GCevent({ MainType, type, date }); // Include date in new event
        await newGCevent.save();
        res.status(201).json({ message: "GC event added successfully", event: newGCevent });
    } catch (error) {
        console.error('Failed to add GC event:', error);
        res.status(500).json({ error: 'Failed to add GC event' });
    }
};
