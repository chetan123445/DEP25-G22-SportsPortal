import admin from 'firebase-admin';
import fs from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const firebaseConnection = async () => {
    try {
        // Read JSON file
        const serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json", "utf8"));

        // Initialize Firebase
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            databaseURL: process.env.FIREBASE_DATABASE_URL, // Store this in .env
        });

        console.log("🔥 Firebase connection established!");

    } catch (error) {
        console.error("Error connecting to Firebase: " + error);
    }
};

export default firebaseConnection;
