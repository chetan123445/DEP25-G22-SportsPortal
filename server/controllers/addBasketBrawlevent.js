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

        // Emit update to all clients watching this event
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
        const event = await BasketBrawlevent.findById(eventId);
        
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
        // Update past events results first
        await updatePastEventResults();

        const events = await BasketBrawlevent.find();
        console.log(`Found ${events.length} BasketBrawl events`);

        // Initialize team sets
        const maleTeams = new Set();
        const femaleTeams = new Set();
        
        // Helper functions for gender check with expanded conditions
        const isMaleTeam = (gender) => {
            const g = gender?.toLowerCase() || '';
            return g === 'male' || g === 'boys' || g === 'm';
        };
        
        const isFemaleTeam = (gender) => {
            const g = gender?.toLowerCase() || '';
            return g === 'female' || g === 'girls' || g === 'f';
        };

        // First pass: collect all unique teams by gender
        events.forEach(event => {
            console.log(`Processing event - Gender: ${event.gender}, Teams: ${event.team1}, ${event.team2}`);
            
            if (isMaleTeam(event.gender)) {
                if (event.team1) maleTeams.add(event.team1);
                if (event.team2) maleTeams.add(event.team2);
            } else if (isFemaleTeam(event.gender)) {
                if (event.team1) femaleTeams.add(event.team1);
                if (event.team2) femaleTeams.add(event.team2);
            }
        });

        console.log('Male Teams:', Array.from(maleTeams));
        console.log('Female Teams:', Array.from(femaleTeams));

        // Initialize stats maps with all teams
        const maleStats = new Map();
        const femaleStats = new Map();

        // Initialize all teams with zero stats
        maleTeams.forEach(team => {
            maleStats.set(team, {
                name: team,
                matches: 0,
                wins: 0,
                losses: 0,
                draws: 0,
                points: 0
            });
        });

        femaleTeams.forEach(team => {
            femaleStats.set(team, {
                name: team,
                matches: 0,
                wins: 0,
                losses: 0,
                draws: 0,
                points: 0
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
        events.forEach(event => {
            const statsMap = isMaleTeam(event.gender) ? maleStats : 
                           isFemaleTeam(event.gender) ? femaleStats : null;
            
            if (!statsMap) return; // Skip if gender is not recognized

            const team1Stats = statsMap.get(event.team1);
            const team2Stats = statsMap.get(event.team2);

            if (team1Stats && team2Stats) {
                // Update matches played
                team1Stats.matches++;
                team2Stats.matches++;

                const isLive = isEventLive(event.date);
                console.log('Event is live:', isLive);

                if (!isLive) {
                    // Only process completed matches
                    if (event.winner === event.team1) {
                        team1Stats.wins++;
                        team2Stats.losses++;
                        team1Stats.points += 2;
                    } else if (event.winner === event.team2) {
                        team2Stats.wins++;
                        team1Stats.losses++;
                        team2Stats.points += 2;
                    } else if (event.winner === 'Draw') {
                        team1Stats.draws++;
                        team2Stats.draws++;
                        team1Stats.points += 1;
                        team2Stats.points += 1;
                    }
                }
            }
        });

        // Sort teams by points and wins
        const sortTeams = (teams) => Array.from(teams.values())
            .sort((a, b) => b.points - a.points || b.wins - a.wins);

        const maleStandingsResult = sortTeams(maleStats);
        const femaleStandingsResult = sortTeams(femaleStats);

        console.log(`Final Standings - Male: ${maleStandingsResult.length} teams, Female: ${femaleStandingsResult.length} teams`);

        res.json({
            maleStandings: maleStandingsResult,
            femaleStandings: femaleStandingsResult
        });
    } catch (error) {
        console.error('Error in getBasketBrawlStandings:', error);
        res.status(500).json({ message: 'Error fetching standings', error });
    }
};
