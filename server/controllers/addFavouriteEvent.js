import userIYSCfavEvent from '../models/userIYSCfavEvent.js';
import userGCfavEvent from '../models/userGCfavEvent.js';
import userIRCCfavEvent from '../models/userIRCCfavEvent.js';
import userBasketBrawlfavEvent from '../models/userBasketBrawlfavEvent.js';
import userPHLfavEvent from '../models/userPHLfavEvent.js';

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
            case 'BasketBrawl':
                favEvent = new userBasketBrawlfavEvent({ userId, eventId });
                break;
            case 'PHL':
                favEvent = new userPHLfavEvent({ userId, eventId });
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
