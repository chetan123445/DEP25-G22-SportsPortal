import IYSCevent from '../models/IYSCevent.js';
import GCevent from '../models/GCevent.js';
import IRCCevent from '../models/IRCCevent.js';
import moment from 'moment';

const addEventType = (events, type, isLive = false) => {
    return events.map(event => ({
        ...event.toObject(),
        eventType: type,
        isLive: isLive
    }));
};

const buildQuery = (req) => {
    const { search } = req.query;
    const query = {};

    if (search) {
        query.$or = [
            { type: new RegExp(search, 'i') },
            { gender: new RegExp(search, 'i') }, // Added gender search
        ];
    }

    return query;
};

export const getLiveEvents = async (req, res) => {
    try {
        const query = buildQuery(req);
        const startOfDay = moment().startOf('day').toDate();
        const endOfDay = moment().endOf('day').toDate();
        query.date = { $gte: startOfDay, $lte: endOfDay };

        const [iyscEvents, gcEvents, irccEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query)
        ]);

        const liveEvents = [
            ...addEventType(iyscEvents, 'IYSC', true),
            ...addEventType(gcEvents, 'GC', true),
            ...addEventType(irccEvents, 'IRCC', true)
        ];

        res.status(200).json(liveEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching live events', error });
    }
};

export const getUpcomingEvents = async (req, res) => {
    try {
        const query = buildQuery(req);
        const tomorrow = moment().add(1, 'days').startOf('day').toDate();
        query.date = { $gte: tomorrow };

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
        const query = buildQuery(req);
        const lastWeek = moment().subtract(1, 'weeks').startOf('day').toDate();
        const today = moment().startOf('day').toDate();
        query.date = { $gte: lastWeek, $lt: today };

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