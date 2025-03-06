import jwt from 'jsonwebtoken';

const generateToken = (user) => {
    const payload = {
        id: user._id,
        email: user.email,
    };

    return jwt.sign(payload, 'your_secret_key', { expiresIn: '1h' });
};

export default generateToken;
