import IYSCevent from '../models/IYSCevent.js';
import GCevent from '../models/GCevent.js';
import IRCCevent from '../models/IRCCevent.js';
import PHLevent from '../models/PHLevent.js';
import BasketBrawlevent from '../models/BasketBrawlevent.js';

const eventModels = {
    'IYSC': IYSCevent,
    'GC': GCevent,
    'IRCC': IRCCevent,
    'PHL': PHLevent,
    'BasketBrawl': BasketBrawlevent
};

export const updateEventDetails = async (req, res) => {
    try {
        const { eventType, eventId, venue, date, time } = req.body;
        const { email } = req.query;

        // Get the corresponding model
        const EventModel = eventModels[eventType];
        if (!EventModel) {
            return res.status(400).json({
                success: false,
                message: 'Invalid event type'
            });
        }

        // Find the event and verify manager
        const event = await EventModel.findById(eventId);
        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        // Verify if the user is an event manager
        const isManager = event.eventManagers.some(manager => 
            manager.email.toLowerCase() === email.toLowerCase()
        );
        
        if (!isManager) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this event'
            });
        }

        // Update the event
        const updatedEvent = await EventModel.findByIdAndUpdate(
            eventId,
            {
                venue,
                date,
                time
            },
            { new: true }
        );

        res.status(200).json({
            success: true,
            data: updatedEvent
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};
