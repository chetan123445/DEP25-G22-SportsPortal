import IYSC from '../models/IYSCevent.js';
import GC from '../models/GCevent.js';
import IRCC from '../models/IRCCevent.js';
import PHL from '../models/PHLevent.js';
import BasketBrawl from '../models/BasketBrawlevent.js';

export const getAllEvents = async (req, res) => {
    try {
        const { search } = req.query;
        
        let filter = {};
        if (search) {
            const searchTerms = search.split(',').map(term => term.trim());
            filter.$and = searchTerms.map(term => {
                const dateSearch = term.match(/^\d{4}-\d{2}-\d{2}$/);
                const searchDate = dateSearch ? new Date(term) : null;
                
                let genderSearch = term;
                if (term.toLowerCase() === 'boys' || term.toLowerCase() === 'male') {
                    genderSearch = 'Male';
                } else if (term.toLowerCase() === 'girls' || term.toLowerCase() === 'female') {
                    genderSearch = 'Female';
                }

                const termFilter = {
                    $or: [
                        { team1: { $regex: term, $options: 'i' } },
                        { team2: { $regex: term, $options: 'i' } },
                        { venue: { $regex: term, $options: 'i' } },
                        { eventType: { $regex: term, $options: 'i' } },
                        { gender: new RegExp(`^${genderSearch}$`, 'i') }
                    ]
                };

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

                return termFilter;
            });
        }

        // Fetch events from all collections with populated team details
        const [iyscEvents, gcEvents, irccEvents, phlEvents, basketBrawlEvents] = await Promise.all([
            IYSC.find(filter).populate('team1Details team2Details'),
            GC.find(filter).populate('participants'),
            IRCC.find(filter).populate('team1Details team2Details'),
            PHL.find(filter).populate('team1Details team2Details'),
            BasketBrawl.find(filter).populate('team1Details team2Details')
        ]);

        // Combine and format events, ensuring date is properly formatted
        let allEvents = [
            ...iyscEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,  // Explicitly include _id
                eventType: 'IYSC',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            })),
            ...gcEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,  // Explicitly include _id
                eventType: 'GC',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            })),
            ...irccEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,  // Explicitly include _id
                eventType: 'IRCC',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            })),
            ...phlEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,  // Explicitly include _id
                eventType: 'PHL',
                date: e.date ? new Date(e.date).toISOString().split('T')[0] : null
            })),
            ...basketBrawlEvents.map(e => ({
                ...e.toObject(),
                _id: e._id,  // Explicitly include _id
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

        if (!updatedEvent) {
            return res.status(404).json({ message: 'Event not found' });
        }

        res.status(200).json({
            ...updatedEvent.toObject(),
            eventType: eventType
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
