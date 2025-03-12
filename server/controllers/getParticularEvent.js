import IYSCEvent from '../models/IYSCevent.js'; // Import the IYSCEvent model
import IRCCevent from '../models/IRCCevent.js'; // Import the IRCCevent model
import PHLevent from '../models/PHLevent.js'; // Import the PHLevent model
import BasketBrawlevent from '../models/BasketBrawlevent.js'; // Import the BasketBrawlevent model
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
    try {
        const { MainType } = req.query;
        const events = await GCevent.find({ MainType });
        res.status(200).json({ data: events });
    } catch (error) {
        res.status(500).json({ message: error.message });
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

export const getPHLevent = async (req, res) => {
    console.log(`Request received: ${JSON.stringify(req.query)}`); // Log the entire query object
    const { type } = req.query;
    console.log(`Received type to fetch phlevents: ${type}`);
  
    if (!type) {
        return res.status(400).json({ message: "Type parameter is required" }); // Handle missing type parameter
    }
  
    try {
        const trimmedtype = type.trim().toLowerCase();
        console.log(`Trimmed and lowercased type: ${trimmedtype}`);
  
        const data = await PHLevent.find({ type: trimmedtype });
        const eventsWithTypes = addEventType(data, 'PHL');
        console.log(`Database query result: ${data}`);
  
        res.status(200).json({ data: eventsWithTypes });
    } catch (error) {
        console.error('Failed to fetch PHLevents:', error);
        res.status(500).json({ error: 'Failed to fetch PHLevents' });
    }
};

export const getBasketBrawlevent = async (req, res) => {
    console.log(`Request received: ${JSON.stringify(req.query)}`); // Log the entire query object
    const { type } = req.query;
    console.log(`Received type to fetch BasketBrawlevents: ${type}`);
  
    if (!type) {
        return res.status(400).json({ message: "Type parameter is required" }); // Handle missing type parameter
    }
  
    try {
        const trimmedtype = type.trim().toLowerCase();
        console.log(`Trimmed and lowercased type: ${trimmedtype}`);
  
        const data = await BasketBrawlevent.find({ type: trimmedtype });
        const eventsWithTypes = addEventType(data, 'BasketBrawl');
        console.log(`Database query result: ${data}`);
  
        res.status(200).json({ data: eventsWithTypes });
    } catch (error) {
        console.error('Failed to fetch BasketBrawlevents:', error);
        res.status(500).json({ error: 'Failed to fetch BasketBrawlevents' });
    }
};
