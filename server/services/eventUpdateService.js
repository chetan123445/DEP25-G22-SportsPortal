import IRCCevent from '../models/IRCCevent.js';
import PHLevent from '../models/PHLevent.js';
import BasketBrawlevent from '../models/BasketBrawlevent.js';

export const updatePastEventResults = async () => {
    const currentDate = new Date();
    
    try {
        // Update IRCC events
        const irccEvents = await IRCCevent.find({
            date: { $lt: currentDate },
            winner: null
        });

        for (const event of irccEvents) {
            if (event.team1Score.runs > event.team2Score.runs) {
                event.winner = event.team1;
            } else if (event.team2Score.runs > event.team1Score.runs) {
                event.winner = event.team2;
            } else {
                event.winner = 'Draw';
            }
            await event.save();
        }

        // Update PHL events
        const phlEvents = await PHLevent.find({
            date: { $lt: currentDate },
            winner: null
        });

        for (const event of phlEvents) {
            if (event.team1Goals > event.team2Goals) {
                event.winner = event.team1;
            } else if (event.team2Goals > event.team1Goals) {
                event.winner = event.team2;
            } else {
                event.winner = 'Draw';
            }
            await event.save();
        }

        // Update BasketBrawl events
        const basketEvents = await BasketBrawlevent.find({
            date: { $lt: currentDate },
            winner: null
        });

        for (const event of basketEvents) {
            if (event.team1Score > event.team2Score) {
                event.winner = event.team1;
            } else if (event.team2Score > event.team1Score) {
                event.winner = event.team2;
            } else {
                event.winner = 'Draw';
            }
            await event.save();
        }

        console.log('Past events updated successfully');
    } catch (error) {
        console.error('Error updating past events:', error);
    }
};
