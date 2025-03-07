import IYSCEvent from '../models/IYSCevent.js'; // Import the IYSCEvent model

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
  
        const data = await IYSCEvent.find({ type: trimmedtype }).select('-password');
        console.log(`Database query result: ${data}`);
  
        res.status(200).json({ data });
    } catch (error) {
        console.error('Failed to fetch IYSCevents:', error);
        res.status(500).json({ error: 'Failed to fetch IYSCevents' });
    }
};
