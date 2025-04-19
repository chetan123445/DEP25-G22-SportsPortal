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
        
        // Get today's date without time component
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        // Get tomorrow's date
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        
        // Set date filter for today only
        query.date = { 
            $gte: today,
            $lt: tomorrow
        };

        const [iyscEvents, gcEvents, irccEvents, phlEvents, basketbrawlEvents] = await Promise.all([
            IYSCevent.find(query),
            GCevent.find(query),
            IRCCevent.find(query),
            PHLevent.find(query),
            BasketBrawlevent.find(query)
        ]);

        // Mark all today's events as live without time check
        const liveEvents = [
            ...iyscEvents.map(event => ({...event.toObject(), eventType: 'IYSC', isLive: true})),
            ...gcEvents.map(event => ({...event.toObject(), eventType: 'GC', isLive: true})),
            ...irccEvents.map(event => ({...event.toObject(), eventType: 'IRCC', isLive: true})),
            ...phlEvents.map(event => ({...event.toObject(), eventType: 'PHL', isLive: true})),
            ...basketbrawlEvents.map(event => ({...event.toObject(), eventType: 'BasketBrawl', isLive: true}))
        ];

        res.status(200).json(liveEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching live events', error });
    }
};

export const getUpcomingEvents = async (req, res) => {
    try {
        const query = buildQuery(req);
        
        // Get tomorrow's date
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);
        
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
        
        // Get today's date
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        query.date = { $lt: today };

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