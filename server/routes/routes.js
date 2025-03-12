import express from 'express';
import { signup } from '../controllers/signup.js';
import { verify_email } from '../controllers/verify_email.js';
import { login } from '../controllers/login.js';
import { getProfile } from '../controllers/profile.js'; // Import the getProfile controller
import { updateProfile } from '../controllers/editProfile.js';
import { addIYSCevent } from '../controllers/addIYSCevent.js';
import { addGCEvent } from '../controllers/addGCevent.js'; // Correct the import statement
import { addIRCCevent } from '../controllers/addIRCCevent.js';
import { addPHLevent } from '../controllers/addPHLevent.js';
import { addBasketBrawlevent } from '../controllers/addBasketBrawlevent.js';
import { getLiveEvents, getUpcomingEvents, getPastEvents } from '../controllers/events.js';
import { getIYSCevent, getGCevent, getIRCCevent, getPHLevent, getBasketBrawlevent } from '../controllers/getParticularEvent.js'; // Import the new controller
import { updateIYSCevent, updateGCevent, updateIRCCevent, updatePHLevent, updateBasketBrawlevent } from '../controllers/updateParticularEvent.js'; // Import the new controller
import { addFavouriteEvent } from '../controllers/addFavouriteEvent.js';
import { removeFavouriteEvent } from '../controllers/removeFavouriteEvent.js';
import { verifyFavouriteEvent } from '../controllers/verifyFavouriteEvent.js';
import { getFavouriteEvent } from '../controllers/getFavouriteEvent.js'; // Correct the import statement

const router = express.Router();

router.post("/signup", signup);
router.post("/verify-email", verify_email);
router.post("/login", login);

router.get("/profile", getProfile); // Ensure this is a GET request
router.patch("/update-profile", updateProfile); // Correct the endpoint to match the frontend

router.post("/add-IYSCevent", addIYSCevent);
router.post("/add-GCevent", addGCEvent); // Ensure the route handler matches the corrected import
router.post("/add-IRCCevent", addIRCCevent);
router.post("/add-PHLevent", addPHLevent);
router.post("/add-BasketBrawlevent", addBasketBrawlevent);

router.get("/live-events", getLiveEvents);
router.get("/upcoming-events", getUpcomingEvents);
router.get("/past-events", getPastEvents);

router.get("/get-iysc-events", getIYSCevent);
router.get("/get-gc-events", getGCevent);
router.get("/get-ircc-events", getIRCCevent);
router.get("/get-phl-events", getPHLevent);
router.get("/get-basketbrawl-events", getBasketBrawlevent);

router.patch("/update-iysc-event", updateIYSCevent);
router.patch("/update-gc-event", updateGCevent);
router.patch("/update-ircc-event", updateIRCCevent);
router.patch("/update-phl-event", updatePHLevent);
router.patch("/update-basketbrawl-event", updateBasketBrawlevent);

router.post("/add-favourite-event", addFavouriteEvent);
router.delete("/remove-favourite-event", removeFavouriteEvent);
router.get("/verify-favourite-event", verifyFavouriteEvent);
router.get("/get-favourite-events", getFavouriteEvent); // Correct the route handler to match the corrected import

export default router;