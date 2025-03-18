import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import morgan from "morgan";
import helmet from "helmet";
import compression from "compression";

import firebaseConnection from './firebaseDatabase/fdb.js';
import DBconnection from './mongodb/mdb.js';

import router from "./routes/routes.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json()); // Handles JSON requests
app.use(express.urlencoded({ extended: true })); // Handles form data
app.use(cors()); // Prevent CORS issues for frontend API calls
app.use(morgan("dev")); // Log HTTP requests
app.use(helmet()); // Improve security
app.use(compression()); // Compress responses for better performance

// Routes
app.use('/', router);

// Database Connections
firebaseConnection();
DBconnection();

// Start the server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});
