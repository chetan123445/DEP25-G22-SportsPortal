import userIYSCfavEvent from '../models/userIYSCfavEvent.js';
import userGCfavEvent from '../models/userGCfavEvent.js';
import userIRCCfavEvent from '../models/userIRCCfavEvent.js';

export const verifyFavouriteEvent = async (req, res) => {
    const { eventType, userId, eventId } = req.query;

    try {
        let favEventModel;
        switch (eventType) {
            case 'IYSC':
                favEventModel = userIYSCfavEvent;
                break;
            case 'GC':
                favEventModel = userGCfavEvent;
                break;
            case 'IRCC':
                favEventModel = userIRCCfavEvent;
                break;
            default:
                return res.status(400).json({ message: 'Invalid event type' });
        }

        const favEvent = await favEventModel.findOne({ userId, eventId });
        if (favEvent) {
            res.status(200).json({ exists: true });
        } else {
            res.status(200).json({ exists: false });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
