import IYSCevent from '../models/IYSCevent.js';
import GCevent from '../models/GCevent.js';
import IRCCevent from '../models/IRCCevent.js';
import PHLevent from '../models/PHLevent.js';
import BasketBrawlevent from '../models/BasketBrawlevent.js';
import moment from 'moment';

const addEventType = (events, type, isLive = false) => {
    return events.map(event => ({
        ...event.toObject(),
        eventType: type,
        isLive: isLive
    }));
};

const buildQuery = (req) => {
    const { search, eventType, gender, year } = req.query;
    const query = {};

    if (search) {
        const dateSearch = moment(search, 'YYYY-MM-DD', true).isValid() ? new Date(search) : null;

        query.$or = [
            { type: new RegExp(search, 'i') },
            { eventType: new RegExp(search, 'i') },
            { gender: new RegExp(search, 'i') },
            ...(dateSearch ? [{ date: dateSearch }] : []),
            { time: new RegExp(search, 'i') },
            { venue: new RegExp(search, 'i') },
            { team1: new RegExp(search, 'i') },
            { team2: new RegExp(search, 'i') },
        ];
    }

    if (eventType) {
        query.eventType = { $in: eventType.split(',') };
    }

    if (gender) {
        query.gender = { $in: gender.split(',') };
    }

    if (year) {
        const years = year.split(',');
        const yearConditions = years.map((y) => {
            if (y === 'Older') {
                return { date: { $lt: new Date('2023-01-01') } };
            }
            return {
                $expr: {
                    $eq: [{ $year: "$date" }, parseInt(y)], // Extract year from date
                },
            };
        });
        query.$and = [...(query.$and || []), { $or: yearConditions }];
    }

    return query;
};

export const getLiveEvents = async (req, res) => {
    try {
        const query = buildQuery(req);
        const startOfDay = moment().startOf('day').toDate();
        const endOfDay = moment().endOf('day').toDate();
        query.date = { $gte: startOfDay, $lte: endOfDay };

        const [iyscEvents, gcEvents, irccEvents, phlEvents, basketbrawlEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query),
            PHLevent.find(query),
            BasketBrawlevent.find(query)
        ]);

        const liveEvents = [
            ...addEventType(iyscEvents, 'IYSC', true),
            ...addEventType(gcEvents, 'GC', true),
            ...addEventType(irccEvents, 'IRCC', true),
            ...addEventType(phlEvents, 'PHL', true),
            ...addEventType(basketbrawlEvents, 'BasketBrawl', true)
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

        const [iyscEvents, gcEvents, irccEvents, phlEvents, basketbrawlEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query),
            PHLevent.find(query),
            BasketBrawlevent.find(query)
        ]);

        const upcomingEvents = [
            ...addEventType(iyscEvents, 'IYSC'),
            ...addEventType(gcEvents, 'GC'),
            ...addEventType(irccEvents, 'IRCC'),
            ...addEventType(phlEvents, 'PHL'),
            ...addEventType(basketbrawlEvents, 'BasketBrawl')
        ];

        res.status(200).json(upcomingEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching upcoming events', error });
    }
};

export const getPastEvents = async (req, res) => {
    try {
        const query = buildQuery(req);
        const today = moment().startOf('day').toDate();
        query.date = { $lt: today }; // Fetch all events before today

        const [iyscEvents, gcEvents, irccEvents, phlEvents, basketbrawlEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query),
            PHLevent.find(query),
            BasketBrawlevent.find(query)
        ]);

        const pastEvents = [
            ...addEventType(iyscEvents, 'IYSC'),
            ...addEventType(gcEvents, 'GC'),
            ...addEventType(irccEvents, 'IRCC'),
            ...addEventType(phlEvents, 'PHL'),
            ...addEventType(basketbrawlEvents, 'BasketBrawl')
        ];

        res.status(200).json(pastEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching past events', error });
    }
};