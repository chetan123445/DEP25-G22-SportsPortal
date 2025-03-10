import IYSCevent from '../models/IYSCevent.js';
import GCevent from '../models/GCevent.js';
import IRCCevent from '../models/IRCCevent.js';
import moment from 'moment';

const addEventType = (events, type) => {
    return events.map(event => ({
        ...event.toObject(),
        eventType: type
    }));
};

export const getLiveEvents = async (req, res) => {
    try {
        const { search } = req.query;
        const startOfDay = moment().startOf('day').toDate();
        const endOfDay = moment().endOf('day').toDate();

        const query = { date: { $gte: startOfDay, $lte: endOfDay } };
        if (search) {
            query.$or = [
                { type:  new RegExp(search, 'i')  },
            ];
        }
        
        const [iyscEvents, gcEvents, irccEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query)
        ]);

        const liveEvents = [
            ...addEventType(iyscEvents, 'IYSC'),
            ...addEventType(gcEvents, 'GC'),
            ...addEventType(irccEvents, 'IRCC')
        ];

        res.status(200).json(liveEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching live events', error });
    }
};

export const getUpcomingEvents = async (req, res) => {
    try {
        const { search } = req.query;
        const tomorrow = moment().add(1, 'days').startOf('day').toDate();

        const query = { date: { $gte: tomorrow } };
        if (search) {
            query.$or = [
                { type:  new RegExp(search, 'i')  },
            ];
        }

        const [iyscEvents, gcEvents, irccEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query)
        ]);

        const upcomingEvents = [
            ...addEventType(iyscEvents, 'IYSC'),
            ...addEventType(gcEvents, 'GC'),
            ...addEventType(irccEvents, 'IRCC')
        ];

        res.status(200).json(upcomingEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching upcoming events', error });
    }
};

export const getPastEvents = async (req, res) => {
    try {
        const { search } = req.query;
        const lastWeek = moment().subtract(1, 'weeks').startOf('day').toDate();
        const today = moment().startOf('day').toDate();

        const query = {date: { $gte: lastWeek, $lt: today }};
        if (search) {
            query.$or = [
                { type:  new RegExp(search, 'i')  },
            ];
        }

        const [iyscEvents, gcEvents, irccEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query)
        ]);

        const pastEvents = [
            ...addEventType(iyscEvents, 'IYSC'),
            ...addEventType(gcEvents, 'GC'),
            ...addEventType(irccEvents, 'IRCC')
        ];

        res.status(200).json(pastEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching past events', error });
    }
};
