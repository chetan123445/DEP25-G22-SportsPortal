import IRCCevent from '../models/IRCCevent.js'; // Import the IRCCevent model

export const addIRCCevent = async (req, res) => {
    const { type, date } = req.body; // Include date in destructuring

    if (!type || !date) { // Check for date
        return res.status(400).json({ message: "Type and date are required" });
    }

    try {
        const newIRCCevent = new IRCCevent({ type, date }); // Include date in new event
        await newIRCCevent.save();
        res.status(201).json({ message: "IRCC event added successfully", event: newIRCCevent });
    } catch (error) {
        console.error('Failed to add IRCC event:', error);
        res.status(500).json({ error: 'Failed to add IRCC event' });
    }
};
