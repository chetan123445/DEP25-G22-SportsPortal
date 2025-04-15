import mongoose from 'mongoose';
import IYSC from '../models/IYSCevent.js';
import GC from '../models/GCevent.js';
import IRCC from '../models/IRCCevent.js';
import PHL from '../models/PHLevent.js';
import BasketBrawl from '../models/BasketBrawlevent.js';
import Team from '../models/Team.js';

export const getAllEvents = async (req, res) => {
    try {
        const { search } = req.query;
        
        let filter = {};
        if (search) {
            const searchTerms = search.split(',').map(term => term.trim());
            filter.$and = searchTerms.map(term => {
                const dateSearch = term.match(/^\d{4}-\d{2}-\d{2}$/);
                const timeSearch = term.match(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/);
                const searchDate = dateSearch ? new Date(term) : null;
                
                let genderSearch = term;
                if (term.toLowerCase() === 'boys' || term.toLowerCase() === 'male') {
                    genderSearch = 'Male';
                } else if (term.toLowerCase() === 'girls' || term.toLowerCase() === 'female') {
                    genderSearch = 'Female';
                }

                const termFilter = {
                    $or: [
                        { team1: { $regex: term, $options: 'i' } },  // Search in team1
                        { team2: { $regex: term, $options: 'i' } },  // Search in team2
                        { venue: { $regex: term, $options: 'i' } },
                        { eventType: { $regex: term, $options: 'i' } },
                        { gender: new RegExp(`^${genderSearch}$`, 'i') }
                    ]
                };

                // Add date search
                if (searchDate && !isNaN(searchDate)) {
                    const nextDay = new Date(searchDate);
                    nextDay.setDate(nextDay.getDate() + 1);
                    termFilter.$or.push({
                        date: {
                            $gte: searchDate,
                            $lt: nextDay
                        }
                    });
                }

                // Add time search
                if (timeSearch) {
                    termFilter.$or.push({
                        time: { $regex: term, $options: 'i' }
                    });
                }

                return termFilter;
            });
        }

        // Fetch events from all collections with proper population
        const [iyscEvents, gcEvents, irccEvents, phlEvents, basketBrawlEvents] = await Promise.all([
            IYSC.find(filter).populate('team1Details team2Details'),
            GC.find(filter).populate({
                path: 'participants',
                model: 'Team',
                select: 'teamName members'
            }),
            IRCC.find(filter).populate('team1Details team2Details'),
            PHL.find(filter).populate('team1Details team2Details'),
            BasketBrawl.find(filter).populate('team1Details team2Details')
        ]);

        // Combine and format events
        let allEvents = [
            ...iyscEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,
                eventType: 'IYSC',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            })),
            ...gcEvents.map(e => {
                const eventObj = {
                    ...e.toObject(),
                    _id: e._id,
                    eventType: 'GC',
                    date: e.date ? new Date(e.date).toISOString().split('T')[0] : null,
                    teamsList: e.participants?.map(team => ({
                        teamId: team._id,
                        teamName: team.teamName,
                        members: team.members
                    })) || []
                };
                return eventObj;
            }),
            ...irccEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,
                eventType: 'IRCC',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            })),
            ...phlEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,
                eventType: 'PHL',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            })),
            ...basketBrawlEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,
                eventType: 'BasketBrawl',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            }))
        ];

        res.status(200).json(allEvents);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const updateEvent = async (req, res) => {
    try {
        const { eventId, eventType, updates } = req.body;
        let EventModel;

        // Select the appropriate model based on event type
        switch (eventType) {
            case 'IYSC': EventModel = IYSC; break;
            case 'GC': EventModel = GC; break;
            case 'IRCC': EventModel = IRCC; break;
            case 'PHL': EventModel = PHL; break;
            case 'BasketBrawl': EventModel = BasketBrawl; break;
            default:
                return res.status(400).json({ message: 'Invalid event type' });
        }

        const existingEvent = await EventModel.findById(eventId);
        if (!existingEvent) {
            return res.status(404).json({ message: 'Event not found' });
        }

        // If updating a GC event
        if (eventType === 'GC') {
            // Filter out team1 and team2 related updates
            const { team1, team2, team1Details, team2Details, ...validUpdates } = updates;
            
            // Update the event
            const updatedEvent = await EventModel.findByIdAndUpdate(
                eventId,
                validUpdates,
                { 
                    new: true,
                    runValidators: true,
                    populate: 'participants'
                }
            );

            return res.status(200).json({
                ...updatedEvent.toObject(),
                eventType: eventType
            });
        }

        // For non-GC events, proceed with normal update
        // If winner field doesn't exist in schema but is being updated,
        // add it to the schema dynamically
        if (updates.hasOwnProperty('winner') && !existingEvent.schema.path('winner')) {
            EventModel.schema.add({
                winner: { type: String, required: false }
            });
        }

        // Validate date format if it's being updated
        if (updates.date) {
            updates.date = new Date(updates.date);
        }

        const updatedEvent = await EventModel.findByIdAndUpdate(
            eventId,
            updates,
            { 
                new: true,
                runValidators: true,
                populate: eventType === 'GC' ? 'participants' : 'team1Details team2Details'
            }
        );

        res.status(200).json({
            ...updatedEvent.toObject(),
            eventType: eventType
        });
    } catch (error) {
        console.error('Error updating event:', error);
        res.status(500).json({ error: error.message });
    }
};

export const deleteEvent = async (req, res) => {
    try {
        const { eventId, eventType } = req.params;
        let EventModel;

        // Select the appropriate model based on event type
        switch (eventType) {
            case 'GC': EventModel = GC; break;
            case 'IYSC': EventModel = IYSC; break;
            case 'IRCC': EventModel = IRCC; break;
            case 'PHL': EventModel = PHL; break;
            case 'BasketBrawl': EventModel = BasketBrawl; break;
            default:
                return res.status(400).json({ message: 'Invalid event type' });
        }

        // Find the event with appropriate population based on event type
        let event;
        if (eventType === 'GC') {
            event = await EventModel.findById(eventId).populate('participants');
            // Delete associated teams
            if (event?.participants?.length > 0) {
                await Team.deleteMany({ _id: { $in: event.participants } });
                console.log('Deleted GC event teams:', event.participants);
            }
        } else {
            event = await EventModel.findById(eventId).populate('team1Details team2Details');
            // Delete associated teams
            if (event.team1Details?._id) {
                await Team.findByIdAndDelete(event.team1Details._id);
            }
            if (event.team2Details?._id) {
                await Team.findByIdAndDelete(event.team2Details._id);
            }
        }

        // Delete the event
        await EventModel.findByIdAndDelete(eventId);
        console.log('Event deleted successfully');

        res.status(200).json({ message: 'Event and associated teams deleted successfully' });
    } catch (error) {
        console.error('Error in deleteEvent:', error);
        res.status(500).json({ error: error.message });
    }
};
