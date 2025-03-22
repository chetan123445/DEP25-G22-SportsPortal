const mongoose = require('mongoose');

const eventManagerSchema = new mongoose.Schema({
    email: {
        type: String,
        required: true,
        unique: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    startDate: {
        type: Date,
        required: true
    },
    endDate: {
        type: Date,
        required: false
    },
    eventIds: [{
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'eventModel'
    }],
    eventModel: {
        type: String,
        required: true,
        enum: ['GCevent', 'IRCCevent', 'IYSCevent', 'PHLevent', 'BasketBrawelevent']
    }
});

const EventManager = mongoose.model('EventManager', eventManagerSchema);

module.exports = EventManager;
