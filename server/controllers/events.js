import IYSCevent from '../models/IYSCevent.js';
import moment from 'moment';

export const getLiveEvents = async (req, res) => {
    try {
        const startOfDay = moment().startOf('day').toDate();
        const endOfDay = moment().endOf('day').toDate();
        const liveEvents = await IYSCevent.find({ date: { $gte: startOfDay, $lte: endOfDay } });
        res.status(200).json(liveEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching live events', error });
    }
};

export const getUpcomingEvents = async (req, res) => {
    try {
        const tomorrow = moment().add(1, 'days').startOf('day').toDate();
        const upcomingEvents = await IYSCevent.find({ date: { $gte: tomorrow } }).sort({ date: 1 });
        res.status(200).json(upcomingEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching upcoming events', error });
    }
};

export const getPastEvents = async (req, res) => {
    try {
        const lastWeek = moment().subtract(1, 'weeks').startOf('day').toDate();
        const today = moment().startOf('day').toDate();
        const pastEvents = await IYSCevent.find({ date: { $gte: lastWeek, $lt: today } }).sort({ date: -1 });
        res.status(200).json(pastEvents);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching past events', error });
    }
};
