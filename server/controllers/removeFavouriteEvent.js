import userIYSCfavEvent from '../models/userIYSCfavEvent.js';
import userGCfavEvent from '../models/userGCfavEvent.js';
import userIRCCfavEvent from '../models/userIRCCfavEvent.js';

export const removeFavouriteEvent = async (req, res) => {
    const { eventType, userId, eventId } = req.body;

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

        const event = await favEventModel.findOneAndDelete({ userId, eventId });

        if (event) {
            res.status(200).json({ message: 'Favorite event removed successfully' });
        } else {
            res.status(404).json({ message: 'Favorite event not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server error', error });
    }
};
