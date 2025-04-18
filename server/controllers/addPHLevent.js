import PHLevent from '../models/PHLevent.js';
import Team from '../models/Team.js';
import { updatePastEventResults } from '../services/eventUpdateService.js';

export const addPHLevent = async (req, res) => {
    try {
        const { 
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
            team1Details, 
            team2Details, 
            eventManagers,
            team1Goals = 0,
            team2Goals = 0,
            commentary = []
        } = req.body;

        // Validate required fields
        if (!gender || !eventType || !type || !date || !time || !venue || !team1 || !team2) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        // Create team1 if details are provided
        let team1Doc = null;
        if (team1Details) {
            const newTeam1 = new Team(team1Details);
            team1Doc = await newTeam1.save();
        }

        // Create team2 if details are provided
        let team2Doc = null;
        if (team2Details) {
            const newTeam2 = new Team(team2Details);
            team2Doc = await newTeam2.save();
        }

        const newEvent = new PHLevent({
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
            eventManagers: eventManagers || [],
            team1Goals,
            team2Goals,
            commentary
        });

        await newEvent.save();
        res.status(201).json({ message: 'Event added successfully', event: newEvent });
    } catch (error) {
        res.status(500).json({ message: 'Error adding event', error });
    }
};

export const updateScore = async (req, res) => {
    try {
        const { eventId, team, increment } = req.body;
        const event = await PHLevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const field = team === 'team1' ? 'team1Goals' : 'team2Goals';
        const currentScore = event[field] || 0;
        event[field] = increment ? (currentScore + 1) : Math.max(0, currentScore - 1);

        // Update winner based on scores
        if (event.team1Goals > event.team2Goals) {
            event.winner = event.team1;
        } else if (event.team2Goals > event.team1Goals) {
            event.winner = event.team2;
        } else {
            event.winner = 'Draw';
        }
        
        await event.save();

        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('score-update', {
                eventId,
                team1Goals: event.team1Goals || 0,
                team2Goals: event.team2Goals || 0
            });
        }

        res.json({ 
            message: 'Score updated successfully', 
            event: {
                ...event.toObject(),
                team1Goals: event.team1Goals || 0,
                team2Goals: event.team2Goals || 0
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
        const event = await PHLevent.findById(eventId);
        
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
        const event = await PHLevent.findById(eventId);
        
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
        const event = await PHLevent.findById(eventId)
            .populate('team1Details')  // Add these populate calls
            .populate('team2Details');
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }
        
        // Format the response to include team players
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

// Add a new controller for standings
export const getPHLStandings = async (req, res) => {
    try {
        const events = await PHLevent.find({ eventType: 'PHL' });
        console.log(`Found ${events.length} PHL events`);

        const maleTeams = new Map();
        const femaleTeams = new Map();

        // Initialize teams with base stats
        events.forEach(event => {
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
        events.forEach(event => {
            const gender = event.gender?.toLowerCase();
            const statsMap = (gender === 'male' || gender === 'boys') ? maleTeams : femaleTeams;
            
            const team1Stats = statsMap.get(event.team1);
            const team2Stats = statsMap.get(event.team2);

            if (!team1Stats || !team2Stats) return;

            const eventDate = new Date(event.date);
            const today = new Date();
            
            // Check if match is past, live, or upcoming
            const isPast = eventDate < new Date(today.setHours(0, 0, 0, 0));
            const isLive = eventDate.toDateString() === today.toDateString();
            const isUpcoming = eventDate > today;

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
                    team1Stats.points += 2; // 2 points for win (changed from 3)
                } else if (event.winner === event.team2) {
                    team2Stats.wins++;
                    team1Stats.losses++;
                    team2Stats.points += 2; // 2 points for win (changed from 3)
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

        const maleStandings = sortTeams(maleTeams);
        const femaleStandings = sortTeams(femaleTeams);

        res.json({
            maleStandings,
            femaleStandings
        });
    } catch (error) {
        console.error('Error in getPHLStandings:', error);
        res.status(500).json({ message: 'Error fetching standings', error });
    }
};
