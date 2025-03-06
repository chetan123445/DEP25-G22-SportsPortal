import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import morgan from "morgan";
import helmet from "helmet";
import compression from "compression";

import firebaseConnection from './firebaseDatabase/fdb.js';
import DBconnection from './mongodb/mdb.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(cors());//frontend (Flutter/Web) makes API calls to this backend, CORS prevents issues with that
// Middleware For Handling Form Data & JSON
app.use(express.json()); // Handles JSON requests
app.use(express.urlencoded({ extended: true })); // Handles form data
app.use(morgan("dev")); // Log HTTP requests
app.use(helmet()); // Improve security
app.use(compression()); // Compress responses for better performance

import router from "./routes/routes.js";

app.use('/', router);

firebaseConnection();
DBconnection();

// Start the server
app.listen(PORT, '0.0.0.0',() => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});