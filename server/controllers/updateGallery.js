import Gallery from '../models/gallery.js'; // Use ES module import

// Function to add an image
const addImage = async (req, res) => {
    try {
        const { file } = req;
        if (!file) {
            return res.status(400).json({ message: 'No image file provided' });
        }

        const newImage = new Gallery({
            image: file.buffer
        });

        await newImage.save();
        res.status(201).json({ message: 'Image added successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error adding image', error: error.message });
    }
};

// Function to get all images
const getImages = async (req, res) => {
    try {
        const images = await Gallery.find();

        const imagesBase64 = images.map(imageDoc => ({
            id: imageDoc._id,
            image: imageDoc.image.toString('base64')
        }));

        res.status(200).json(imagesBase64);
    } catch (error) {
        res.status(500).json({ message: 'Error retrieving images', error: error.message });
    }
};

// Function to delete images
const deleteImages = async (req, res) => {
    try {
        const { imageIds } = req.body;
        if (!imageIds || !Array.isArray(imageIds)) {
            return res.status(400).json({ message: 'Invalid image IDs' });
        }

        await Gallery.deleteMany({ _id: { $in: imageIds } });
        res.status(200).json({ message: 'Images deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting images', error: error.message });
    }
};

export { addImage, getImages, deleteImages }; // Use ES module export