import IRCCevent from '../models/IRCCevent.js';
import Team from '../models/Team.js';
import { updatePastEventResults } from '../services/eventUpdateService.js';

export const addIRCCevent = async (req, res) => {
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
            eventManagers = [], // Add default empty array for event managers
            team1Score = {     // Add default score object for team1
                runs: 0,
                wickets: 0,
                overs: 0,
                balls: 0
            },
            team2Score = {     // Add default score object for team2
                runs: 0,
                wickets: 0,
                overs: 0,
                balls: 0
            },
            commentary = []    // Add default empty array for commentary
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

        const newEvent = new IRCCevent({
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
            team1Score,    // Add team1Score
            team2Score,    // Add team2Score
            commentary,    // Add commentary array
            eventManagers  // Add event managers array
        });

        await newEvent.save();
        
        // Format the response to include formatted scores
        const response = {
            message: 'Event added successfully',
            event: {
                ...newEvent.toObject(),
                team1Score: newEvent.getFormattedScore('team1'),
                team2Score: newEvent.getFormattedScore('team2')
            }
        };

        res.status(201).json(response);
    } catch (error) {
        console.error('Error adding IRCC event:', error);
        res.status(500).json({ message: 'Error adding event', error: error.message });
    }
};

export const updateScore = async (req, res) => {
    try {
        const { eventId, team, scoreType, increment } = req.body;
        const event = await IRCCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const score = team === 'team1' ? event.team1Score : event.team2Score;

        switch (scoreType) {
            case 'runs':
                score.runs = increment ? score.runs + 1 : Math.max(0, score.runs - 1);
                break;
            case 'four':
                if (increment) {
                    score.runs = score.runs + 4;
                } else {
                    score.runs = Math.max(0, score.runs - 4);
                }
                break;
            case 'six':
                if (increment) {
                    score.runs = score.runs + 6;
                } else {
                    score.runs = Math.max(0, score.runs - 6);
                }
                break;
            case 'wickets':
                if (increment) {
                    score.wickets = Math.min(10, score.wickets + 1);
                } else {
                    score.wickets = Math.max(0, score.wickets - 1);
                }
                break;
            case 'ball':
                if (increment) {
                    score.balls = score.balls + 1;
                    if (score.balls >= 6) {
                        score.overs = score.overs + 1;
                        score.balls = 0;
                    }
                } else {
                    if (score.balls > 0) {
                        score.balls = score.balls - 1;
                    } else if (score.overs > 0) {
                        score.overs = score.overs - 1;
                        score.balls = 5;
                    }
                }
                break;
            case 'nb':
            case 'wd':
                // For both No Ball and Wide, add one run but don't increment the ball count
                score.runs = score.runs + 1;
                break;
        }

        // Update winner logic
        if (event.team1Score.runs > event.team2Score.runs) {
            event.winner = event.team1;
        } else if (event.team2Score.runs > event.team1Score.runs) {
            event.winner = event.team2;
        } else {
            event.winner = 'draw';
        }

        await event.save();
        
        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('score-update', {
                eventId,
                team1Score: event.team1Score,
                team2Score: event.team2Score,
                winner: event.winner
            });
        }

        res.json({ 
            message: 'Score updated successfully', 
            event: {
                ...event.toObject(),
                winner: event.winner
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
        const event = await IRCCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        // Create new commentary object
        const newCommentary = { text, timestamp };
        event.commentary.push(newCommentary);
        await event.save();

        // Get the newly added commentary with its ID
        const addedCommentary = event.commentary[event.commentary.length - 1];
        
        const io = req.app.get('io');
        if (io) {
            // Emit to all clients in the event room
            io.to(eventId).emit('commentary-update', {
                eventId,
                newComment: {
                    id: addedCommentary._id,
                    text: addedCommentary.text,
                    timestamp: addedCommentary.timestamp
                },
                type: 'add'
            });
        }

        res.json({ 
            message: 'Commentary added successfully', 
            commentary: addedCommentary 
        });
    } catch (error) {
        console.error('Error adding commentary:', error);
        res.status(500).json({ message: 'Error adding commentary', error: error.message });
    }
};

export const deleteCommentary = async (req, res) => {
    try {
        const { eventId, commentaryId } = req.body;
        const event = await IRCCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        event.commentary = event.commentary.filter(
            comment => comment._id.toString() !== commentaryId
        );
        await event.save();

        const io = req.app.get('io');
        if (io) {
            // Emit the delete event to all clients in the room with the commentaryId
            io.to(eventId).emit('commentary-update', {
                eventId,
                type: 'delete',
                commentaryId: commentaryId
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
        const event = await IRCCevent.findById(eventId)
            .populate('team1Details')
            .populate('team2Details');
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }
        
        const response = {
            ...event.toObject(),
            team1Score: event.getFormattedScore('team1'),
            team2Score: event.getFormattedScore('team2'),
            team1Players: event.team1Details ? event.team1Details.members : [],
            team2Players: event.team2Details ? event.team2Details.members : []
        };
        
        res.json({ event: response });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching event details', error });
    }
};

export const getIRCCStandings = async (req, res) => {
    try {
        const events = await IRCCevent.find({ eventType: 'IRCC' });
        console.log(`Found ${events.length} IRCC events`);

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
            maleStandings: sortTeams(maleTeams),
            femaleStandings: sortTeams(femaleTeams)
        });
    } catch (error) {
        console.error('Error in getIRCCStandings:', error);
        res.status(500).json({ message: 'Error fetching standings', error });
    }
};

export const updateWinner = async (req, res) => {
    try {
        const { eventId, winner, status } = req.body;
        const event = await IRCCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        event.winner = winner;
        event.status = status;
        await event.save();

        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('winner-update', {
                eventId,
                winner,
                status
            });
        }

        res.json({ 
            message: 'Winner updated successfully', 
            event
        });
    } catch (error) {
        console.error('Error updating winner:', error);
        res.status(500).json({ message: 'Error updating winner', error: error.message });
    }
};
