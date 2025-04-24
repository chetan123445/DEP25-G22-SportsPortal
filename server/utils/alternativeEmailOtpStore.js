class AlternativeEmailOtpStore {
    constructor() {
        this.otps = new Map();
    }

    setOtp(email, otp) {
        this.otps.set(email, otp.toString());
        // Auto-clear after 10 minutes
        setTimeout(() => this.deleteOtp(email), 600000);
    }

    getOtp(email) {
        return this.otps.get(email);
    }

    deleteOtp(email) {
        this.otps.delete(email);
    }
}

export const alternativeEmailOtpStore = new AlternativeEmailOtpStore();
