import mongoose from 'mongoose';

const IYSCeventSchema = new mongoose.Schema({
    gender: { type: String, required: true },
    eventType: { type: String, required: true },
    type: { type: String, required: true },
    date: { type: Date, required: true },
    time: { type: String, required: true },
    venue: { type: String, required: true },
    description: { type: String, required: false },
    winner: { type: String, required: false },
    team1: { type: String, required: true },
    team2: { type: String, required: true },
    team1Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: false },
    team2Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: false },
    eventManagers: [{
        name: { type: String, required: true },
        email: { type: String, required: true }
    }],
    team1Score: {
        runs: { type: Number, default: 0 },
        wickets: { type: Number, default: 0 },
        overs: { type: Number, default: 0 },
        balls: { type: Number, default: 0 },
        goals: { type: Number, default: 0 },
        rounds: [{ type: Number, default: 0 }]
    },
    team2Score: {
        runs: { type: Number, default: 0 },
        wickets: { type: Number, default: 0 },
        overs: { type: Number, default: 0 },
        balls: { type: Number, default: 0 },
        goals: { type: Number, default: 0 },
        rounds: [{ type: Number, default: 0 }]
    },
    commentary: [{
        text: String,
        timestamp: { type: Date, default: Date.now }
    }]
});

IYSCeventSchema.methods.getFormattedScore = function(team) {
    const score = team === 'team1' ? this.team1Score : this.team2Score;
    const sportType = this.type.toLowerCase();
    
    if (sportType === 'cricket') {
        return {
            scoreString: `${score.runs}/${score.wickets}`,
            oversString: `${score.overs}.${score.balls}`
        };
    } else if (['hockey', 'football'].includes(sportType)) {
        return {
            scoreString: `${score.goals}`,
            roundsString: ''
        };
    } else {
        // For volleyball, basketball, tennis, table tennis, etc.
        return {
            scoreString: score.goals,
            roundsString: score.rounds.join(' - ')
        };
    }
};

IYSCeventSchema.methods.isValidScoreUpdate = function(team, scoreType) {
    if (this.type.toLowerCase() === 'cricket') {
        return ['runs', 'wickets', 'overs', 'balls', 'nb', 'wd', 'four', 'six'].includes(scoreType);
    } else if (['hockey', 'football'].includes(this.type.toLowerCase())) {
        return ['goals'].includes(scoreType);
    } else {
        return ['goals', 'rounds'].includes(scoreType);
    }
};

const IYSCevent = mongoose.model('IYSCevent', IYSCeventSchema);

export default IYSCevent;