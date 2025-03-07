import express from 'express';
import { signup } from '../controllers/signup.js';
import { verify_email } from '../controllers/verify_email.js';
import { login } from '../controllers/login.js';
import { getProfile } from '../controllers/profile.js'; // Import the getProfile controller
import { updateProfile } from '../controllers/editProfile.js';
import { addIYSCevent } from '../controllers/addIYSCevent.js';
import { getLiveEvents, getUpcomingEvents, getPastEvents } from '../controllers/events.js';
import { getIYSCevent } from '../controllers/getIYSCevent.js'; // Import the new controller

const router = express.Router();

router.post("/signup", signup);
router.post("/verify-email", verify_email);
router.post("/login", login);
router.get("/profile", getProfile); // Ensure this is a GET request
router.patch("/update-profile", updateProfile);
router.post("/add-IYSCevent", addIYSCevent);
router.get("/live-events", getLiveEvents);
router.get("/upcoming-events", getUpcomingEvents);
router.get("/past-events", getPastEvents);
router.get("/iyscevents", getIYSCevent); // Add new route for fetching IYSC events by type

export default router;