# 🎨 DrawBattle

A cross-platform AI-powered drawing challenge app where players receive a prompt, draw simultaneously, and get ranked by an AI based on how closely their drawing matches the prompt.

## Architecture

```
draw-battle/
├── flutter_app/     # Cross-platform mobile app (Flutter/Dart)
├── backend/         # API server (Node.js/Express)
└── README.md
```

### Tech Stack

| Layer        | Technology                           |
|--------------|--------------------------------------|
| Frontend     | Flutter (CustomPaint canvas)         |
| Backend      | Node.js + Express + Socket.IO        |
| AI (Primary) | Google Cloud Vision API              |
| AI (Fallback)| TensorFlow.js                        |
| Auth         | Firebase Authentication              |
| Database     | Cloud Firestore                      |
| Storage      | Firebase Cloud Storage               |
| Real-time    | Firestore listeners + Socket.IO      |

## Getting Started

### Prerequisites

- **Node.js** v18+ and npm
- **Flutter SDK** v3.24+ (for mobile app)
- **Firebase project** with Authentication, Firestore, and Cloud Storage enabled
- **Google Cloud Vision API key** (optional — TF.js fallback available)

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy environment config
cp .env.example .env
# Edit .env with your Firebase service account path and API keys

# Start development server
npm run dev
```

The server starts at `http://localhost:3000`. Test with:
```bash
curl http://localhost:3000/api/health
```

### Flutter App Setup

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Configure Firebase
flutterfire configure

# Run on device/emulator
flutter run
```

### API Endpoints

| Method | Endpoint                    | Description              | Auth |
|--------|-----------------------------|--------------------------|------|
| GET    | `/api/health`               | Health check             | No   |
| POST   | `/api/auth/profile`         | Create/update profile    | Yes  |
| GET    | `/api/auth/profile`         | Get my profile           | Yes  |
| POST   | `/api/games`                | Create game session      | Yes  |
| GET    | `/api/games`                | List available games     | No   |
| POST   | `/api/games/:id/join`       | Join a game              | Yes  |
| POST   | `/api/games/:id/ready`      | Ready up                 | Yes  |
| POST   | `/api/games/:id/start`      | Start game (host only)   | Yes  |
| POST   | `/api/drawings/submit`      | Submit drawing           | Yes  |
| GET    | `/api/drawings/:gameId`     | Get game results         | No   |
| GET    | `/api/leaderboard`          | Global leaderboard       | No   |
| GET    | `/api/leaderboard/me`       | My rank & stats          | Yes  |
| GET    | `/api/stats/me`             | My detailed stats        | Yes  |
| GET    | `/api/stats/me/history`     | My game history          | Yes  |
| GET    | `/api/stats/:userId`        | Public player stats      | No   |
| POST   | `/api/matchmaking/join`     | Join matchmaking queue   | Yes  |
| POST   | `/api/matchmaking/leave`    | Leave matchmaking queue  | Yes  |
| GET    | `/api/matchmaking/status`   | My queue position        | Yes  |
| GET    | `/api/matchmaking/stats`    | Global queue stats       | No   |
| GET    | `/api/achievements/me`      | My unlocked badges       | Yes  |
| GET    | `/api/achievements/me/all`  | My badges catalog status | Yes  |
| GET    | `/api/achievements/:userId` | Public player badges      | No   |
| GET    | `/api/daily`                | Get today's daily challenge| No   |
| POST   | `/api/daily/submit`         | Submit daily result      | Yes  |
| GET    | `/api/daily/leaderboard`    | Today's daily leaderboard| No   |
| GET    | `/api/daily/me/history`     | My daily history         | Yes  |

### AI Scoring Pipeline

1. **Preprocess**: Resize to 256×256, normalize
2. **Feature Extract**: Coverage, edge density, content detection
3. **AI Evaluation**:
   - Google Vision API: Label & web entity detection
   - TensorFlow.js: Quick, Draw! model classification (fallback)
4. **Score Calculation**:
   - AI Similarity (80% weight)
   - Speed Bonus (up to 10%)
   - Quality Bonus (up to 10%)
   - Streak Multiplier (up to 10%)

### Real-time Events (Socket.IO)

| Event                 | Direction | Description                    |
|-----------------------|-----------|--------------------------------|
| `game:join`           | Client→   | Join a game room               |
| `game:leave`          | Client→   | Leave a game room              |
| `user:identify`       | Client→   | Register user for notifications|
| `game:started`        | →Client   | Game started with prompt       |
| `drawing:submitted`   | →Client   | A player submitted             |
| `game:results`        | →Client   | Final rankings                 |
| `matchmaking:matched` | →Client   | Matchmaking found a game       |
| `chat:message`        | Client↔   | Send or receive in-game chat   |
| `chat:reaction`       | Client↔   | Send or receive emoji reaction |
| `chat:error`          | →Client   | Rate-limiting or chat errors   |

## Deployment

### Frontend (Firebase Hosting)
The Flutter Web frontend has been successfully deployed to Firebase Hosting:
- **Hosting URL**: [https://drawbattle-io-19283.web.app](https://drawbattle-io-19283.web.app)

To redeploy the frontend:
```bash
cd flutter_app
flutter build web --release
cd ..
firebase deploy --only hosting
```

### Backend (Railway)
The Node.js socket backend is successfully deployed and running on Railway:
- **Backend API URL**: [https://draw-battle-backend-production.up.railway.app](https://draw-battle-backend-production.up.railway.app)
- **Health Check**: [https://draw-battle-backend-production.up.railway.app/api/health](https://draw-battle-backend-production.up.railway.app/api/health)

To redeploy the backend:
```bash
railway up ./backend --path-as-root --service draw-battle-backend --detach
```

## License

MIT
