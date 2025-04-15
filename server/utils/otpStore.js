const otpMap = new Map(); // In-memory store (use Redis for production)

export const otpStore = {
    setOtp: (email, otp, name, hashedPassword, ttl = 600000) => { // TTL in milliseconds (default: 10 minutes)
        const normalizedEmail = email.toLowerCase();
        otpMap.set(normalizedEmail, { otp, name, hashedPassword });
        setTimeout(() => otpMap.delete(normalizedEmail), ttl); // Auto-delete after TTL
    },
    getOtpData: (email) => {
        const normalizedEmail = email.toLowerCase();
        return otpMap.get(normalizedEmail);
    },
    deleteOtp: (email) => {
        const normalizedEmail = email.toLowerCase();
        otpMap.delete(normalizedEmail);
    },
};