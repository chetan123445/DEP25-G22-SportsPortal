import mongoose from 'mongoose';

const gallerySchema = new mongoose.Schema({
    image: {
        type: Buffer,
        required: true
    }
});

const Gallery = mongoose.model('Gallery', gallerySchema);

export default Gallery; // Use ES module export