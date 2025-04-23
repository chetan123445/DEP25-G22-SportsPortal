class OtpStore {
    constructor() {
        this.otps = new Map();
    }

    setOtp(email, otp) {
        this.otps.set(email, {
            otp,
            timestamp: Date.now()
        });
    }

    getOtp(email) {
        const data = this.otps.get(email);
        if (!data) return null;
        
        // Check if OTP is expired (10 minutes)
        if (Date.now() - data.timestamp > 600000) {
            this.deleteOtp(email);
            return null;
        }
        
        return data.otp;
    }

    deleteOtp(email) {
        this.otps.delete(email);
    }
}

export const otpStore = new OtpStore();