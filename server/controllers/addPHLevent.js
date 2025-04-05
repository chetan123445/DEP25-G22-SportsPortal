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

        event.commentary.push({ text, timestamp });
        await event.save();
        
        // Emit update to all clients watching this event
        const io = req.app.get('io');
        io.to(eventId).emit('commentary-update', {
            eventId,
            commentary: event.commentary
        });

        res.json({ message: 'Commentary added successfully', event });
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
        
        res.json({ message: 'Commentary deleted successfully', event });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting commentary', error });
    }
};

// Add a new controller to get event details
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
        // Update past events results first
        await updatePastEventResults();

        // Fetch all PHL events
        const events = await PHLevent.find({ eventType: 'PHL' });
        console.log(`Found ${events.length} PHL events`);

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
        console.error('Error in getPHLStandings:', error);
        res.status(500).json({ message: 'Error fetching standings', error });
    }
};
