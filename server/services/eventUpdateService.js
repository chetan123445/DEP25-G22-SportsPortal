import PHLevent from '../models/PHLevent.js';
import BasketBrawlevent from '../models/BasketBrawlevent.js';
import IRCCevent from '../models/IRCCevent.js';

const updatePastEventResults = async () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Function to determine winner
    const determineWinner = (team1Score, team2Score, team1, team2) => {
        if (team1Score > team2Score) return team1;
        if (team2Score > team1Score) return team2;
        if (team1Score === team2Score) return 'Draw';
        return null;
    };

    // Update PHL events
    const phlEvents = await PHLevent.find({
        date: { $lt: today },
        winner: null
    });

    for (const event of phlEvents) {
        const winner = determineWinner(event.team1Score, event.team2Score, event.team1, event.team2);
        if (winner) {
            event.winner = winner;
            await event.save();
        }
    }

    // Update BasketBrawl events
    const basketBrawlEvents = await BasketBrawlevent.find({
        date: { $lt: today },
        winner: null
    });

    for (const event of basketBrawlEvents) {
        const winner = determineWinner(event.team1Score, event.team2Score, event.team1, event.team2);
        if (winner) {
            event.winner = winner;
            await event.save();
        }
    }

    // Update IRCC events
    const irccEvents = await IRCCevent.find({
        date: { $lt: today },
        winner: null
    });

    for (const event of irccEvents) {
        if (event.team1Score && event.team2Score) {
            if (event.team1Score.runs > event.team2Score.runs) {
                event.winner = event.team1;
            } else if (event.team2Score.runs > event.team1Score.runs) {
                event.winner = event.team2;
            } else {
                event.winner = 'Draw';
            }
            await event.save();
        }
    }
};

export { updatePastEventResults };
