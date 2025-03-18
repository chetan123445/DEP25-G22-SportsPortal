import userIYSCfavEvent from '../models/userIYSCfavEvent.js';
import userIRCCfavEvent from '../models/userIRCCfavEvent.js';
import userGCfavEvent from '../models/userGCfavEvent.js';
import userBasketBrawlfavEvent from '../models/userBasketBrawlfavEvent.js';
import userPHLfavEvent from '../models/userPHLfavEvent.js';

export const getFavouriteEvent = async (req, res) => {
    try {
        const { userId } = req.query;
        if (!userId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        const favouriteIYSCEvents = await userIYSCfavEvent.find({ userId: userId });
        const favouriteIRCCEvents = await userIRCCfavEvent.find({ userId: userId });
        const favouriteGCEvents = await userGCfavEvent.find({ userId: userId });
        const favouriteBasketBrawlEvents = await userBasketBrawlfavEvent.find({ userId: userId });
        const favouritePHLEvents = await userPHLfavEvent.find({ userId: userId });

        const favouriteEvents = {
            IYSC: favouriteIYSCEvents,
            IRCC: favouriteIRCCEvents,
            GC: favouriteGCEvents,
            BasketBrawl: favouriteBasketBrawlEvents,
            PHL: favouritePHLEvents
        };

        res.status(200).json(favouriteEvents);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
