// Import necessary modules
import express from 'express';
import notificationsRouter from './routes/notifications.js';

const app = express();

// Middleware
app.use(express.json());

// Routes
app.use('/notifications', notificationsRouter);

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});