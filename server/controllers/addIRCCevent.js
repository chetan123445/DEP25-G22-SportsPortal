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
            case 'wickets':
                score.wickets = increment ? Math.min(10, score.wickets + 1) : Math.max(0, score.wickets - 1);
                break;
            case 'ball':
                score.balls = score.balls + 1;
                if (score.balls >= 6) {
                    score.overs = score.overs + 1;
                    score.balls = 0;
                }
                break;
        }

        // Update winner based on scores - similar to PHL's approach
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

        event.commentary.push({ text, timestamp });
        await event.save();
        
        const io = req.app.get('io');
        if (io) {
            io.to(eventId).emit('commentary-update', {
                eventId,
                commentary: event.commentary
            });
        }

        res.json({ message: 'Commentary added successfully', event });
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
        
        res.json({ message: 'Commentary deleted successfully', event });
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
        // Update past events results first
        await updatePastEventResults();

        // Fetch all IRCC events
        const events = await IRCCevent.find({ eventType: 'IRCC' });
        console.log(`Found ${events.length} IRCC events`);

        // Separate teams by gender
        const maleTeams = new Set();
        const femaleTeams = new Set();
        
        // Helper function to check gender
        const isMaleTeam = (gender) => {
            return gender?.toLowerCase() === 'male' || gender?.toLowerCase() === 'boys';
        };
        
        const isFemaleTeam = (gender) => {
            return gender?.toLowerCase() === 'female' || gender?.toLowerCase() === 'girls';
        };

        // First pass: collect all teams by gender
        events.forEach((event, index) => {
            console.log(`\nProcessing event ${index + 1}:`);
            console.log('Gender:', event.gender);
            console.log('Team 1:', event.team1);
            console.log('Team 2:', event.team2);
            
            if (isMaleTeam(event.gender)) {
                if (event.team1) maleTeams.add(event.team1);
                if (event.team2) maleTeams.add(event.team2);
            } else if (isFemaleTeam(event.gender)) {
                if (event.team1) femaleTeams.add(event.team1);
                if (event.team2) femaleTeams.add(event.team2);
            }
        });

        console.log('\nCollected Teams:');
        console.log('Male Teams:', Array.from(maleTeams));
        console.log('Female Teams:', Array.from(femaleTeams));

        // Initialize stats maps
        const maleStats = new Map();
        const femaleStats = new Map();

        // Initialize all teams with zero stats
        maleTeams.forEach(team => {
            maleStats.set(team, {
                name: team,
                wins: 0,
                losses: 0,
                draws: 0,
                points: 0,
                matches: 0
            });
        });

        femaleTeams.forEach(team => {
            femaleStats.set(team, {
                name: team,
                wins: 0,
                losses: 0,
                draws: 0,
                points: 0,
                matches: 0
            });
        });

        // Helper function to check if event is live
        const isEventLive = (eventDate) => {
            const today = new Date();
            const eventDay = new Date(eventDate);
            return eventDay.getFullYear() === today.getFullYear() &&
                   eventDay.getMonth() === today.getMonth() &&
                   eventDay.getDate() === today.getDate();
        };

        // Process match results
        events.forEach((event, index) => {
            console.log(`\nProcessing results for event ${index + 1}:`);
            const statsMap = isMaleTeam(event.gender) ? maleStats : femaleStats;
            const team1Stats = statsMap.get(event.team1);
            const team2Stats = statsMap.get(event.team2);

            if (team1Stats && team2Stats) {
                team1Stats.matches++;
                team2Stats.matches++;

                const isLive = isEventLive(event.date);
                console.log('Event is live:', isLive);

                if (!isLive) { // Only process completed matches
                    if (event.winner) {
                        console.log('Winner:', event.winner);
                        if (event.winner === 'Draw') {
                            team1Stats.draws++;
                            team2Stats.draws++;
                            team1Stats.points += 1;
                            team2Stats.points += 1;
                        } else if (event.winner === event.team1) {
                            team1Stats.wins++;
                            team2Stats.losses++;
                            team1Stats.points += 2;
                        } else if (event.winner === event.team2) {
                            team2Stats.wins++;
                            team1Stats.losses++;
                            team2Stats.points += 2;
                        }
                    } else {
                        // For completed matches without a winner, count as draw
                        team1Stats.draws++;
                        team2Stats.draws++;
                        team1Stats.points += 1;
                        team2Stats.points += 1;
                        console.log('Non-live match with no winner - counted as draw');
                    }
                } else {
                    console.log('Live match - no points awarded yet');
                }
            }
        });

        // Sort and prepare final standings
        const sortTeams = (teams) => Array.from(teams.values()).sort((a, b) => {
            if (b.points !== a.points) return b.points - a.points;
            if (b.wins !== a.wins) return b.wins - a.wins;
            return b.matches - a.matches;
        });

        const maleStandingsResult = sortTeams(maleStats);
        const femaleStandingsResult = sortTeams(femaleStats);

        console.log('\nFinal Standings Count:');
        console.log('Male Teams:', maleStandingsResult.length);
        console.log('Female Teams:', femaleStandingsResult.length);

        res.json({
            maleStandings: maleStandingsResult,
            femaleStandings: femaleStandingsResult
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
