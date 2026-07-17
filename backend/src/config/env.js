import dotenv from 'dotenv';
dotenv.config();

const env = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json',
  googleVisionApiKey: process.env.GOOGLE_VISION_API_KEY || '',
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  groqApiKey: process.env.GROQ_API_KEY || '',
  aiModelMode: process.env.AI_MODEL_MODE || 'vision',
  tfModelPath: process.env.TF_MODEL_PATH || './models/quickdraw',
  defaultDrawingTime: parseInt(process.env.DEFAULT_DRAWING_TIME || '60', 10),
  maxPlayersPerGame: parseInt(process.env.MAX_PLAYERS_PER_GAME || '6', 10),

  get isDev() {
    return this.nodeEnv === 'development';
  },

  get isProd() {
    return this.nodeEnv === 'production';
  },

  validate() {
    const warnings = [];
    if (!this.googleVisionApiKey) {
      warnings.push('GOOGLE_VISION_API_KEY not set — Vision API scoring disabled, using TensorFlow.js fallback');
    }
    if (warnings.length > 0) {
      warnings.forEach(w => console.warn(`⚠️  ${w}`));
    }
    return true;
  }
};

export default env;
