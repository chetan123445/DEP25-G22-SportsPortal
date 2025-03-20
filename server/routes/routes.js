import express from 'express';
import { signup } from '../controllers/signup.js';
import { verify_email } from '../controllers/verify_email.js';
import { login } from '../controllers/login.js';
import { getProfile } from '../controllers/profile.js';
import { updateProfile, uploadProfilePic, removeProfilePic, upload } from '../controllers/editProfile.js';
import { addIYSCevent } from '../controllers/addIYSCevent.js';
import { addGCEvent } from '../controllers/addGCevent.js';
import { addIRCCevent } from '../controllers/addIRCCevent.js';
import { addPHLevent } from '../controllers/addPHLevent.js';
import { addBasketBrawlevent } from '../controllers/addBasketBrawlevent.js';
import { getLiveEvents, getUpcomingEvents, getPastEvents } from '../controllers/events.js';
import { getIYSCevent, getGCevent, getIRCCevent, getPHLevent, getBasketBrawlevent } from '../controllers/getParticularEvent.js';
import { updateIYSCevent, updateGCevent, updateIRCCevent, updatePHLevent, updateBasketBrawlevent } from '../controllers/updateParticularEvent.js';
import { addFavouriteEvent } from '../controllers/addFavouriteEvent.js';
import { removeFavouriteEvent } from '../controllers/removeFavouriteEvent.js';
import { verifyFavouriteEvent } from '../controllers/verifyFavouriteEvent.js';
import { getFavouriteEvent } from '../controllers/getFavouriteEvent.js';

const router = express.Router();

router.post("/signup", signup);
router.post("/verify-email", verify_email);
router.post("/login", login);

router.get("/profile", getProfile);
router.patch("/update-profile", updateProfile);

router.post("/add-IYSCevent", addIYSCevent);
router.post("/add-GCevent", addGCEvent);
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
router.get("/get-favourite-events", getFavouriteEvent);

router.post("/upload-profile-pic", upload.single('profilePic'), uploadProfilePic);
router.patch("/remove-profile-pic", removeProfilePic);

export default router;