import IYSCevent from '../models/IYSCevent.js';
import GCevent from '../models/GCevent.js';
import IRCCevent from '../models/IRCCevent.js';
import PHLevent from '../models/PHLevent.js';
import BasketBrawlevent from '../models/BasketBrawlevent.js';

export const getManagedEvents = async (req, res) => {
    try {
        const { email } = req.query;

        // Query all event collections
        const [iyscEvents, gcEvents, irccEvents, phlEvents, basketEvents] = await Promise.all([
            IYSCevent.find({ 'eventManagers.email': email }),
            GCevent.find({ 'eventManagers.email': email }),
            IRCCevent.find({ 'eventManagers.email': email }),
            PHLevent.find({ 'eventManagers.email': email }),
            BasketBrawlevent.find({ 'eventManagers.email': email })
        ]);

        // Combine and format results
        const managedEvents = {
            IYSC: iyscEvents,
            GC: gcEvents,
            IRCC: irccEvents,
            PHL: phlEvents,
            BasketBrawl: basketEvents
        };

        res.status(200).json({
            success: true,
            data: managedEvents
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};
