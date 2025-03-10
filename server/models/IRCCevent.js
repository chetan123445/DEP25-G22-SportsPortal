import mongoose from 'mongoose';

const IRCCeventSchema = new mongoose.Schema({
    type: { type: String, required: true },
    date: { type: Date, required: true } // Add date attribute
});

const IRCCevent = mongoose.model('IRCCevent', IRCCeventSchema);

export default IRCCevent; // Use ES6 export syntax
