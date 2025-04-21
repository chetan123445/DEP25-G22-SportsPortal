import BasketBrawlevent from '../models/BasketBrawlevent.js';
import Team from '../models/Team.js';
import { updatePastEventResults } from '../services/eventUpdateService.js';

export const addBasketBrawlevent = async (req, res) => {
    try {
        const { gender, eventType, type, date, time, venue, description, winner, team1, team2, team1Details, team2Details, eventManagers } = req.body;

        // Validate required fields
        if (!gender || !eventType || !type || !date || !time || !venue || !team1 || !team2) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        // Create team1 if details are provided
        let team1Doc = null;
        if (team1Details && team1Details.members && team1Details.members.length > 0) {
            const newTeam1 = new Team({
                teamName: team1Details.teamName,
                members: team1Details.members
            });
            team1Doc = await newTeam1.save();
        }

        // Create team2 if details are provided
        let team2Doc = null;
        if (team2Details && team2Details.members && team2Details.members.length > 0) {
            const newTeam2 = new Team({
                teamName: team2Details.teamName,
                members: team2Details.members
            });
            team2Doc = await newTeam2.save();
        }

        // Prepare event managers array
        const eventManagersArray = Array.isArray(eventManagers) ? eventManagers : [];

        const newEvent = new BasketBrawlevent({
            gender,
            eventType,
            type,
            date,
            time,
            venue,
            description,
            winner,
            team1,
            team2,
            team1Details: team1Doc ? team1Doc._id : null,
            team2Details: team2Doc ? team2Doc._id : null,
            eventManagers: eventManagersArray
        });

        await newEvent.save();
        res.status(201).json({ message: 'Event added successfully', event: newEvent });
    } catch (error) {
        console.error('Error in addBasketBrawlevent:', error); // Add this debug line
        res.status(500).json({ message: 'Error adding event', error: error.message });
    }
};

export const updateScore = async (req, res) => {
    try {
        const { eventId, team, increment } = req.body;
        const event = await BasketBrawlevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const field = team === 'team1' ? 'team1Score' : 'team2Score';
        const currentScore = event[field] || 0;
        event[field] = increment ? (currentScore + 1) : Math.max(0, currentScore - 1);

        // Update winner based on scores
        if (event.team1Score > event.team2Score) {
            event.winner = event.team1;
        } else if (event.team2Score > event.team1Score) {
            event.winner = event.team2;
        } else {
            event.winner = 'Draw';
        }
        
        await event.save();

        // Emit score update through socket
        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('score-update', {
                eventId,
                team1Score: event.team1Score || 0,
                team2Score: event.team2Score || 0
            });
        }

        res.json({ 
            message: 'Score updated successfully', 
            event: {
                ...event.toObject(),
                team1Score: event.team1Score || 0,
                team2Score: event.team2Score || 0
            }
        });
    } catch (error) {
        console.error('Error updating score:', error);
        res.status(500).json({ message: 'Error updating score', error: error.message });
    }
};

export const addMatchCommentary = async (req, res) => {
    try {
        const { eventId, text, timestamp } = req.body;
        const event = await BasketBrawlevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const newCommentary = { text, timestamp };
        event.commentary = [newCommentary, ...event.commentary]; // Changed: Add to start of array
        await event.save();

        const addedCommentary = event.commentary[0]; // Get the first (newest) commentary
        
        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('commentary-update', {
                eventId,
                type: 'add',
                newComment: {
                    id: addedCommentary._id,
                    text: addedCommentary.text,
                    timestamp: addedCommentary.timestamp
                }
            });
        }

        res.json({ 
            message: 'Commentary added successfully', 
            commentary: addedCommentary 
        });
    } catch (error) {
        res.status(500).json({ message: 'Error adding commentary', error });
    }
};

export const deleteCommentary = async (req, res) => {
    try {
        const { eventId, commentaryId } = req.body;
        const event = await BasketBrawlevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        event.commentary = event.commentary.filter(
            comment => comment._id.toString() !== commentaryId
        );
        await event.save();

        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('commentary-update', {
                eventId,
                type: 'delete',
                commentaryId
            });
        }
        
        res.json({ 
            message: 'Commentary deleted successfully',
            commentaryId
        });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting commentary', error });
    }
};

export const getEventDetails = async (req, res) => {
    try {
        const { eventId } = req.params;
        const event = await BasketBrawlevent.findById(eventId)
            .populate('team1Details')
            .populate('team2Details');
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }
        
        // Always include team players in response
        const response = {
            ...event.toObject(),
            team1Players: event.team1Details ? event.team1Details.members : [],
            team2Players: event.team2Details ? event.team2Details.members : []
        };
        
        res.json({ event: response });
    } catch (error) {
        console.error('Error fetching event details:', error);
        res.status(500).json({ message: 'Error fetching event details', error });
    }
};

export const getBasketBrawlStandings = async (req, res) => {
    try {
        const year = req.query.year ? parseInt(req.query.year) : null;
        const events = await BasketBrawlevent.find({ eventType: 'Basket Brawl' });
        console.log(`Found ${events.length} BasketBrawl events`);

        // Get unique years from events
        const uniqueYears = [...new Set(events.map(event => 
            new Date(event.date).getFullYear()
        ))].sort((a, b) => b - a);

        // Filter events by year
        const currentYear = new Date().getFullYear();
        const filteredEvents = year 
            ? events.filter(event => new Date(event.date).getFullYear() === year)
            : events.filter(event => new Date(event.date).getFullYear() === currentYear);

        const maleTeams = new Map();
        const femaleTeams = new Map();

        // Initialize teams with base stats
        filteredEvents.forEach(event => {
            const gender = event.gender?.toLowerCase();
            const statsMap = (gender === 'male' || gender === 'boys') ? maleTeams : femaleTeams;

            [event.team1, event.team2].forEach(team => {
                if (team && !statsMap.has(team)) {
                    statsMap.set(team, {
                        teamName: team,
                        matchesPlayed: 0,
                        wins: 0,
                        losses: 0,
                        draws: 0,
                        points: 0
                    });
                }
            });
        });

        // Calculate stats for each event
        filteredEvents.forEach(event => {
            const gender = event.gender?.toLowerCase();
            const statsMap = (gender === 'male' || gender === 'boys') ? maleTeams : femaleTeams;
            
            const team1Stats = statsMap.get(event.team1);
            const team2Stats = statsMap.get(event.team2);

            if (!team1Stats || !team2Stats) return;

            const eventDate = new Date(event.date);
            const today = new Date(new Date().setHours(0, 0, 0, 0));

            // Check if match is past, live, or upcoming
            const isPast = eventDate < today;
            const isLive = eventDate.toDateString() === today.toDateString();
            
            if (isPast) {
                // For completed matches
                team1Stats.matchesPlayed++;
                team2Stats.matchesPlayed++;

                if (event.winner === 'Draw' || !event.winner) {
                    team1Stats.draws++;
                    team2Stats.draws++;
                    team1Stats.points += 1; // 1 point for draw
                    team2Stats.points += 1;
                } else if (event.winner === event.team1) {
                    team1Stats.wins++;
                    team2Stats.losses++;
                    team1Stats.points += 2; // 2 points for win
                } else if (event.winner === event.team2) {
                    team2Stats.wins++;
                    team1Stats.losses++;
                    team2Stats.points += 2;
                }
            } else if (isLive) {
                // For live matches, only increment matches played
                team1Stats.matchesPlayed++;
                team2Stats.matchesPlayed++;
            }
            // Do nothing for upcoming matches
        });

        const sortTeams = teams => 
            Array.from(teams.values())
                .sort((a, b) => b.points - a.points || b.wins - a.wins);

        res.json({
            years: uniqueYears,
            currentYear: year || currentYear,
            maleStandings: sortTeams(maleTeams),
            femaleStandings: sortTeams(femaleTeams)
        });
    } catch (error) {
        console.error('Error in getBasketBrawlStandings:', error);
        res.status(500).json({ message: 'Error fetching standings', error });
    }
};
