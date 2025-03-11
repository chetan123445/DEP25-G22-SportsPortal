import userIYSCfavEvent from '../models/userIYSCfavEvent.js';
import userGCfavEvent from '../models/userGCfavEvent.js';
import userIRCCfavEvent from '../models/userIRCCfavEvent.js';

export const addFavouriteEvent = async (req, res) => {
    const { eventType, userId, eventId } = req.body;

    try {
        let favEvent;
        switch (eventType) {
            case 'IYSC':
                favEvent = new userIYSCfavEvent({ userId, eventId });
                break;
            case 'GC':
                favEvent = new userGCfavEvent({ userId, eventId });
                break;
            case 'IRCC':
                favEvent = new userIRCCfavEvent({ userId, eventId });
                break;
            default:
                return res.status(400).json({ message: 'Invalid event type' });
        }

        await favEvent.save();
        res.status(201).json({ message: 'Favorite event added successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
