import mongoose from 'mongoose';

const IRCCeventSchema = new mongoose.Schema({
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
    team1Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: false }, // Use TeamSchema for team1Details
    team2Details: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', required: false }, // Use TeamSchema for team2Details
    team1Score: {
        runs: { type: Number, default: 0 },
        wickets: { type: Number, default: 0 },
        overs: { type: Number, default: 0 },
        balls: { type: Number, default: 0 }
    },
    team2Score: {
        runs: { type: Number, default: 0 },
        wickets: { type: Number, default: 0 },
        overs: { type: Number, default: 0 },
        balls: { type: Number, default: 0 }
    },
    commentary: [{
        text: String,
        timestamp: { type: Date, default: Date.now }
    }],
    eventManagers: [{
        name: { type: String, required: true },
        email: { type: String, required: true }
    }]
});

// Add method to get formatted score
IRCCeventSchema.methods.getFormattedScore = function(team) {
    const score = team === 'team1' ? this.team1Score : this.team2Score;
    return {
        scoreString: `${score.runs}/${score.wickets}`,
        oversString: `${score.overs}.${score.balls}`
    };
};

const IRCCevent = mongoose.model('IRCCevent', IRCCeventSchema);

export default IRCCevent;
