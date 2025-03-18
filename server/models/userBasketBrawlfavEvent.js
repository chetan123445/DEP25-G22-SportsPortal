import mongoose from 'mongoose';

const userBasketBrawlfavSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'BasketBrawlevent', required: true },
});

const userBasketBrawlfavEvent = mongoose.model('userBasketBrawlfavEvent', userBasketBrawlfavSchema);

export default userBasketBrawlfavEvent;
