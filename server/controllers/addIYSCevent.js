import IYSCevent from '../models/IYSCevent.js';
import Team from '../models/Team.js';

export const addIYSCevent = async (req, res) => {
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
            commentary = [], // Add default empty array for commentary
            team1Score = {
                runs: 0,
                wickets: 0,
                overs: 0,
                balls: 0,
                goals: 0,
                rounds: []
            },
            team2Score = {
                runs: 0,
                wickets: 0,
                overs: 0,
                balls: 0,
                goals: 0,
                rounds: []
            }
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

        const newEvent = new IYSCevent({
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
            team1Score,
            team2Score,
            eventManagers: eventManagers || [],
            commentary // Add commentary array to new event
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
        res.status(500).json({ message: 'Error adding event', error });
    }
};

export const updateScore = async (req, res) => {
    try {
        const { eventId, team, scoreType, increment } = req.body;
        const event = await IYSCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const score = team === 'team1' ? event.team1Score : event.team2Score;

        if (scoreType === 'completeRound') {
            // Save current round scores to history
            event.team1Score.roundHistory.push({
                roundNumber: event.team1Score.currentRound,
                score: event.team1Score.goals
            });
            event.team2Score.roundHistory.push({
                roundNumber: event.team2Score.currentRound,
                score: event.team2Score.goals
            });

            // Increment round number and reset scores
            event.team1Score.currentRound++;
            event.team2Score.currentRound++;
            event.team1Score.goals = 0;
            event.team2Score.goals = 0;
        } else if (scoreType === 'goals') {
            score.goals = increment ? score.goals + 1 : Math.max(0, score.goals - 1);
        } else {
            switch (event.type.toLowerCase()) {
                case 'cricket':
                    updateCricketScore(score, scoreType, increment);
                    break;
                case 'hockey':
                case 'football':
                    updateGoalScore(score, increment);
                    break;
                default:
                    // For round-based sports, keep rounds in sync for both teams
                    if (scoreType === 'rounds') {
                        updateRoundBasedScore(score, scoreType, increment);
                        updateRoundBasedScore(otherScore, scoreType, increment);
                    } else {
                        updateRoundBasedScore(score, scoreType, increment, roundIndex);
                    }
            }
        }

        updateWinner(event);
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

        res.json({ message: 'Score updated successfully', event });
    } catch (error) {
        res.status(500).json({ message: 'Error updating score', error: error.message });
    }
};

function updateCricketScore(score, scoreType, increment) {
    switch (scoreType) {
        case 'runs':
            score.runs = increment ? score.runs + 1 : Math.max(0, score.runs - 1);
            break;
        case 'four':
            score.runs = increment ? score.runs + 4 : Math.max(0, score.runs - 4);
            break;
        case 'six':
            score.runs = increment ? score.runs + 6 : Math.max(0, score.runs - 6);
            break;
        case 'wickets':
            score.wickets = increment ? Math.min(10, score.wickets + 1) : Math.max(0, score.wickets - 1);
            break;
        case 'overs':
            if (increment) {
                score.overs++;
                score.balls = 0;  // Reset balls when incrementing overs
            } else {
                if (score.overs > 0) {
                    score.overs--;
                }
            }
            break;
        case 'balls':
            if (increment) {
                score.balls++;
                if (score.balls >= 6) {
                    score.overs++;
                    score.balls = 0;
                }
            } else {
                if (score.balls > 0) {
                    score.balls--;
                } else if (score.overs > 0) {
                    score.overs--;
                    score.balls = 5;
                }
            }
            break;
        case 'nb':
        case 'wd':
            if (increment) score.runs++;
            break;
    }
}

function updateGoalScore(score, increment) {
    score.goals = increment ? score.goals + 1 : Math.max(0, score.goals - 1);
}

function updateRoundBasedScore(score, scoreType, increment, roundIndex = 0) {
    if (scoreType === 'goals') {
        score.goals = increment ? score.goals + 1 : Math.max(0, score.goals - 1);
    } else if (scoreType === 'rounds') {
        if (!Array.isArray(score.rounds)) {
            score.rounds = [];
        }

        // Add new round
        if (increment && roundIndex >= score.rounds.length) {
            score.rounds.push({
                roundNumber: score.rounds.length + 1,
                score: 0
            });
        }
        // Remove last round
        else if (!increment && score.rounds.length > 0) {
            score.rounds.pop();
        }
    } else if (scoreType === 'roundScore') {
        if (roundIndex < score.rounds.length) {
            score.rounds[roundIndex].score = increment 
                ? score.rounds[roundIndex].score + 1 
                : Math.max(0, score.rounds[roundIndex].score - 1);
        }
    }
}

function updateWinner(event) {
    if (event.type.toLowerCase() === 'cricket') {
        // For cricket: Compare total runs
        if (event.team1Score.runs > event.team2Score.runs) {
            event.winner = event.team1;
        } else if (event.team2Score.runs > event.team1Score.runs) {
            event.winner = event.team2;
        } else {
            event.winner = 'draw';
        }
    } else {
        // For round-based sports like basketball, volleyball, etc.
        const team1RoundsWon = event.team1Score.roundHistory.reduce((count, round) => 
            count + (round.score > event.team2Score.roundHistory[round.roundNumber - 1].score ? 1 : 0), 0);
            
        const team2RoundsWon = event.team1Score.roundHistory.reduce((count, round) => 
            count + (round.score < event.team2Score.roundHistory[round.roundNumber - 1].score ? 1 : 0), 0);

        if (team1RoundsWon > team2RoundsWon) {
            event.winner = event.team1;
        } else if (team2RoundsWon > team1RoundsWon) {
            event.winner = event.team2;
        } else {
            event.winner = 'draw';
        }
    }
}

export const addMatchCommentary = async (req, res) => {
    try {
        const { eventId, text, timestamp } = req.body;
        const event = await IYSCevent.findById(eventId);
        
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const newCommentary = { text, timestamp };
        event.commentary = [newCommentary, ...event.commentary]; // Add to start of array
        await event.save();

        const addedCommentary = event.commentary[0]; // Get the first (newest) commentary
        
        const io = req.app.get('io');
        if (io) {
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

        res.status(200).json({ 
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
        const event = await IYSCevent.findById(eventId);
        
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
                commentaryId: commentaryId
            });
        }
        
        res.status(200).json({ 
            message: 'Commentary deleted successfully', 
            commentaryId 
        });
    } catch (error) {
        console.error('Error deleting commentary:', error);
        res.status(500).json({ message: 'Error deleting commentary', error: error.message });
    }
};

export const getIYSCStandings = async (req, res) => {
    try {
        const year = req.query.year ? parseInt(req.query.year) : null;
        const events = await IYSCevent.find();
        const sportTypes = [
            'cricket',
            'hockey',
            'football',
            'table tennis',
            'tennis',
            'badminton',
            'basketball',
            'volleyball'
        ];

        // Get unique years from events
        const uniqueYears = [...new Set(events.map(event => 
            new Date(event.date).getFullYear()
        ))].sort((a, b) => b - a);

        // Filter events by year
        const currentYear = new Date().getFullYear();
        const filteredEvents = year 
            ? events.filter(event => new Date(event.date).getFullYear() === year)
            : events.filter(event => new Date(event.date).getFullYear() === currentYear);

        const standings = [];

        // Helper function to normalize gender
        const normalizeGender = (gender) => {
            if (!gender) return null;
            gender = gender.toLowerCase().trim();
            if (['male', 'boys', 'boy', 'm'].includes(gender)) return 'male';
            if (['female', 'girls', 'girl', 'f'].includes(gender)) return 'female';
            return null;
        };

        for (const sportType of sportTypes) {
            const sportEvents = filteredEvents.filter(event => 
                event.type.toLowerCase() === sportType
            );

            const maleTeams = new Map();
            const femaleTeams = new Map();

            // Process each event for the current sport type
            sportEvents.forEach(event => {
                const normalizedGender = normalizeGender(event.gender);
                if (!normalizedGender) return;

                const statsMap = normalizedGender === 'male' ? maleTeams : femaleTeams;

                [event.team1, event.team2].forEach(team => {
                    if (!statsMap.has(team)) {
                        statsMap.set(team, {
                            name: team,
                            type: sportType,
                            gender: normalizedGender,
                            matches: 0,
                            wins: 0,
                            losses: 0,
                            draws: 0,
                            points: 0
                        });
                    }
                });

                const team1Stats = statsMap.get(event.team1);
                const team2Stats = statsMap.get(event.team2);

                if (!team1Stats || !team2Stats) return;

                const eventDate = new Date(event.date);
                const today = new Date();
                today.setHours(0, 0, 0, 0);

                const isCompleted = eventDate < today;
                const isLive = eventDate.getFullYear() === today.getFullYear() &&
                             eventDate.getMonth() === today.getMonth() &&
                             eventDate.getDate() === today.getDate();

                // Update matches played for both completed and live matches
                if (isCompleted || isLive) {
                    team1Stats.matches++;
                    team2Stats.matches++;
                }

                // Update points only for completed matches
                if (isCompleted) {
                    // Modified this section to handle null winner
                    if (!event.winner || event.winner === 'Draw' || event.winner === 'draw') {
                        // Draw or no winner declared - each team gets 1 point
                        team1Stats.draws++;
                        team2Stats.draws++;
                        team1Stats.points++;
                        team2Stats.points++;
                    } else if (event.winner === event.team1) {
                        // Team 1 won - gets 2 points
                        team1Stats.wins++;
                        team2Stats.losses++;
                        team1Stats.points += 2;
                    } else if (event.winner === event.team2) {
                        // Team 2 won - gets 2 points
                        team2Stats.wins++;
                        team1Stats.losses++;
                        team2Stats.points += 2;
                    }
                }
            });

            // Add teams to standings array
            maleTeams.forEach(team => standings.push(team));
            femaleTeams.forEach(team => standings.push(team));
        }

        // Sort standings by points and wins
        standings.sort((a, b) => b.points - a.points || b.wins - a.wins);

        res.json({ 
            years: uniqueYears,
            currentYear: year || currentYear,
            standings 
        });
    } catch (error) {
        console.error('Error fetching standings:', error);
        res.status(500).json({ message: 'Error fetching standings', error });
    }
};

export const getEventDetails = async (req, res) => {
    try {
        const { eventId } = req.params;
        const event = await IYSCevent.findById(eventId)
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
