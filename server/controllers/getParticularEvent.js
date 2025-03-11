import IYSCEvent from '../models/IYSCevent.js'; // Import the IYSCEvent model
import IRCCevent from '../models/IRCCevent.js'; // Import the IRCCevent model
import GCevent from '../models/GCevent.js'; // Import the GCevent model

const addEventType = (events, type) => {
    return events.map(event => ({
        ...event.toObject(),
        eventType: type
    }));
};

export const getIYSCevent = async (req, res) => {
    console.log(`Request received: ${JSON.stringify(req.query)}`); // Log the entire query object
    const { type } = req.query;
    console.log(`Received type to fetch iyscevents: ${type}`);
  
    if (!type) {
        return res.status(400).json({ message: "Type parameter is required" }); // Handle missing type parameter
    }
  
    try {
        const trimmedtype = type.trim().toLowerCase();
        console.log(`Trimmed and lowercased type: ${trimmedtype}`);
  
        const data = await IYSCEvent.find({ type: trimmedtype });
        const eventsWithTypes = addEventType(data, 'IYSC');
        console.log(`Database query result: ${data}`);
  
        res.status(200).json({ data: eventsWithTypes });
    } catch (error) {
        console.error('Failed to fetch IYSCevents:', error);
        res.status(500).json({ error: 'Failed to fetch IYSCevents' });
    }
};

export const getGCevent = async (req, res) => {
    console.log(`Request received: ${JSON.stringify(req.query)}`); // Log the entire query object
    const { MainType, type } = req.query;
    console.log(`Received MainType to fetch gcevents: ${MainType}, type: ${type}`);
  
    if (!MainType || !type) {
        return res.status(400).json({ message: "MainType and type parameters are required" }); // Handle missing parameters
    }
  
    try {
        const trimmedMainType = MainType.trim().toLowerCase();
        const trimmedType = type.trim().toLowerCase();
        console.log(`Trimmed and lowercased MainType: ${trimmedMainType}, type: ${trimmedType}`);
  
        const data = await GCevent.find({ MainType: trimmedMainType, type: trimmedType });
        const eventsWithTypes = addEventType(data, 'GC');
        console.log(`Database query result: ${data}`);
  
        res.status(200).json({ data: eventsWithTypes });
    } catch (error) {
        console.error('Failed to fetch GCevents:', error);
        res.status(500).json({ error: 'Failed to fetch GCevents' });
    }
};

export const getIRCCevent = async (req, res) => {
    console.log(`Request received: ${JSON.stringify(req.query)}`); // Log the entire query object
    const { type } = req.query;
    console.log(`Received type to fetch irccevents: ${type}`);
  
    if (!type) {
        return res.status(400).json({ message: "Type parameter is required" }); // Handle missing type parameter
    }
  
    try {
        const trimmedtype = type.trim().toLowerCase();
        console.log(`Trimmed and lowercased type: ${trimmedtype}`);
  
        const data = await IRCCevent.find({ type: trimmedtype });
        const eventsWithTypes = addEventType(data, 'IRCC');
        console.log(`Database query result: ${data}`);
  
        res.status(200).json({ data: eventsWithTypes });
    } catch (error) {
        console.error('Failed to fetch IRCCevents:', error);
        res.status(500).json({ error: 'Failed to fetch IRCCevents' });
    }
};
