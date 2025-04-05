import mongoose from 'mongoose';

const BasketBrawleventSchema = new mongoose.Schema({
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
    team1Score: { type: Number, default: 0 },
    team2Score: { type: Number, default: 0 },
    commentary: [{
        text: String,
        timestamp: { type: Date, default: Date.now }
    }],
    eventManagers: [{
        name: { type: String, required: true },
        email: { type: String, required: true }
    }]
});

const BasketBrawlevent = mongoose.model('BasketBrawlevent', BasketBrawleventSchema);

export default BasketBrawlevent;
