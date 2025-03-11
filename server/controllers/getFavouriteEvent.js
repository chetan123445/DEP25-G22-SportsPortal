import userIYSCfavEvent from '../models/userIYSCfavEvent.js';
import userIRCCfavEvent from '../models/userIRCCfavEvent.js';
import userGCfavEvent from '../models/userGCfavEvent.js';

export const getFavouriteEvent = async (req, res) => {
    try {
        const { userId } = req.query; // Extract userId correctly
        if (!userId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        const favouriteIYSCEvents = await userIYSCfavEvent.find({ userId: userId });
        const favouriteIRCCEvents = await userIRCCfavEvent.find({ userId: userId });
        const favouriteGCEvents = await userGCfavEvent.find({ userId: userId });

        const favouriteEvents = {
            IYSC: favouriteIYSCEvents,
            IRCC: favouriteIRCCEvents,
            GC: favouriteGCEvents
        };

        res.status(200).json(favouriteEvents);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
