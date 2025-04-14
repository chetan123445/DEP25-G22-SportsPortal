import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import morgan from "morgan";
import helmet from "helmet";
import compression from "compression";
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { Server } from 'socket.io';
import { createServer } from 'http';

import firebaseConnection from './firebaseDatabase/fdb.js';
import DBconnection from './mongodb/mdb.js';

import router from "./routes/routes.js";
import { updatePastEventResults } from './services/eventUpdateService.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// // Create uploads directory if it doesn't exist
// const __filename = fileURLToPath(import.meta.url);
// const __dirname = path.dirname(__filename);
// const uploadsDir = path.join(__dirname, 'uploads');
// if (!fs.existsSync(uploadsDir)) {
//     fs.mkdirSync(uploadsDir);
// }

// Middleware
app.use(express.json()); // Handles JSON requests
app.use(express.urlencoded({ extended: true })); // Handles form data
app.use(cors()); // Prevent CORS issues for frontend API calls
app.use(morgan("dev")); // Log HTTP requests
app.use(helmet()); // Improve security
app.use(compression()); // Compress responses for better performance

// // Serve static files from the uploads directory
// app.use('/uploads', express.static(uploadsDir));

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*", // In production, replace with your frontend URL
    methods: ["GET", "POST"]
  }
});

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join-event', (eventId) => {
    socket.join(eventId);
    console.log(`User ${socket.id} joined event ${eventId}`);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Make io accessible to routes
app.set('io', io);

// Add this after your other middleware setup
// Run update at midnight every day
setInterval(async () => {
    const now = new Date();
    if (now.getHours() === 0 && now.getMinutes() === 0) {
        try {
            await updatePastEventResults();
            console.log('Updated past event results');
        } catch (error) {
            console.error('Error updating past event results:', error);
        }
    }
}, 60000); // Check every minute

// Routes
app.use('/', router);

// Database Connections
firebaseConnection();
DBconnection();

// Start the server
httpServer.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});
