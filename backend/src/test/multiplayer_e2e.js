import { io as ioClient } from 'socket.io-client';
import http from 'http';
import sharp from 'sharp';

const SERVER_URL = process.env.TEST_SERVER_URL || 'http://localhost:3000';

function log(step, msg) {
  console.log(`[E2E TEST - ${step}] ${msg}`);
}

function error(step, msg) {
  console.error(`[E2E TEST FAIL - ${step}] ❌ ${msg}`);
}

async function runTest() {
  console.log('\n==================================================');
  console.log('  🚀 STARTING MULTIPLAYER END-TO-END MATCH TEST');
  console.log('==================================================\n');

  let p1Socket, p2Socket;
  let roomCode = null;

  // Create a non-blank 200x200 test drawing image with sharp (a circle outline for wolf)
  const TEST_DRAWING_PNG = await sharp({
    create: {
      width: 200,
      height: 200,
      channels: 4,
      background: { r: 255, g: 255, b: 255, alpha: 1 },
    },
  })
    .composite([
      {
        input: Buffer.from(
          `<svg width="200" height="200">
            <circle cx="100" cy="100" r="60" stroke="black" stroke-width="5" fill="none" />
            <polygon points="70,50 85,90 55,90" fill="black" />
            <polygon points="130,50 145,90 115,90" fill="black" />
          </svg>`
        ),
        top: 0,
        left: 0,
      },
    ])
    .png()
    .toBuffer();

  try {
    // Step 1: Connect Player 1 & Player 2 sockets
    log('CONNECT', 'Connecting Player 1 and Player 2 sockets...');
    p1Socket = ioClient(SERVER_URL, { transports: ['websocket'] });
    p2Socket = ioClient(SERVER_URL, { transports: ['websocket'] });

    await Promise.all([
      new Promise((res, rej) => {
        p1Socket.on('connect', res);
        p1Socket.on('connect_error', rej);
      }),
      new Promise((res, rej) => {
        p2Socket.on('connect', res);
        p2Socket.on('connect_error', rej);
      }),
    ]);
    log('CONNECT', '✅ Both players connected via Socket.IO');

    // Step 2: Player 1 creates room
    log('ROOM_CREATE', 'Player 1 creating room...');
    const createPromise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Room creation timeout')), 5000);
      p1Socket.once('room:created', (data) => {
        clearTimeout(timer);
        resolve(data.roomCode);
      });
      p1Socket.emit('room:create', {
        uid: 'p1_test_uid',
        displayName: 'Player One',
      });
    });

    roomCode = await createPromise;
    log('ROOM_CREATE', `✅ Room created: ${roomCode}`);

    // Step 3: Player 2 joins room
    log('ROOM_JOIN', `Player 2 joining room ${roomCode}...`);
    const joinPromise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Room join timeout')), 5000);
      p1Socket.on('room:update', (data) => {
        if (data.players.length === 2) {
          clearTimeout(timer);
          resolve(data);
        }
      });
      p2Socket.emit('room:join', {
        roomCode,
        uid: 'p2_test_uid',
        displayName: 'Player Two',
      });
    });

    const roomUpdate = await joinPromise;
    log('ROOM_JOIN', `✅ Player 2 joined. Room total players: ${roomUpdate.players.length}`);

    // Step 4: Player 2 ready up
    log('READY', 'Player 2 marking ready...');
    p2Socket.emit('room:toggle_ready', { roomCode, uid: 'p2_test_uid' });
    await new Promise(r => setTimeout(r, 500));
    log('READY', '✅ Player 2 ready');

    // Step 5: Player 1 starts match
    log('MATCH_START', 'Host starting match...');

    const countdownPromise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Countdown event timeout')), 5000);
      p1Socket.once('match:countdown', (data) => {
        clearTimeout(timer);
        resolve(data);
      });
    });

    const startPromise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Match start event timeout')), 8000);
      p1Socket.once('match:start', (data) => {
        clearTimeout(timer);
        resolve(data);
      });
    });

    p1Socket.emit('match:start', {
      roomCode,
      difficulty: 'easy',
      category: 'animals',
      duration: 30,
      rounds: 1,
    });

    const countdownData = await countdownPromise;
    log('MATCH_START', `✅ Countdown received: prompt="${countdownData.prompt}", 3s timer`);

    const startData = await startPromise;
    log('MATCH_START', `✅ Match start received: prompt="${startData.prompt}", duration=${startData.duration}s`);

    // Step 6: Submit drawings for both players via REST endpoint
    log('SUBMIT', 'Submitting drawing PNGs for Player 1 and Player 2...');

    const resultsPromise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Game results socket event timeout (60s)')), 60000);
      p1Socket.once('game:results', (data) => {
        clearTimeout(timer);
        resolve(data);
      });
    });

    // Helper for HTTP multipart submission
    const submitDrawingHttp = (userId, userToken) => {
      return new Promise((resolve, reject) => {
        const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
        let body = '';
        body += `--${boundary}\r\n`;
        body += `Content-Disposition: form-data; name="gameId"\r\n\r\n${roomCode}\r\n`;
        body += `--${boundary}\r\n`;
        body += `Content-Disposition: form-data; name="drawing"; filename="drawing.png"\r\n`;
        body += `Content-Type: image/png\r\n\r\n`;

        const postData = Buffer.concat([
          Buffer.from(body, 'utf8'),
          TEST_DRAWING_PNG,
          Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8'),
        ]);

        const req = http.request(`${SERVER_URL}/api/drawings/submit`, {
          method: 'POST',
          headers: {
            'Content-Type': `multipart/form-data; boundary=${boundary}`,
            'Content-Length': postData.length,
            'Authorization': `Bearer ${userToken}`,
          },
        }, (res) => {
          let resData = '';
          res.on('data', chunk => resData += chunk);
          res.on('end', () => {
            try {
              resolve(JSON.parse(resData));
            } catch (err) {
              reject(err);
            }
          });
        });

        req.on('error', reject);
        req.write(postData);
        req.end();
      });
    };

    const [sub1, sub2] = await Promise.all([
      submitDrawingHttp('p1_test_uid', 'mock_token_p1_test_uid'),
      submitDrawingHttp('p2_test_uid', 'mock_token_p2_test_uid'),
    ]);

    log('SUBMIT', `✅ Player 1 submission HTTP response: success=${sub1.success}`);
    log('SUBMIT', `✅ Player 2 submission HTTP response: success=${sub2.success}`);

    // Step 7: Await AI Evaluation and Results via Socket
    log('EVALUATION', 'Waiting for AI Evaluation & game:results socket emission...');
    const results = await resultsPromise;

    log('EVALUATION', `✅ Game results received! Winner ID: ${results.winnerId}`);
    console.log('\n--- Match Scoreboard ---');
    for (const [uid, pData] of Object.entries(results.drawings || {})) {
      console.log(`  👤 ${pData.displayName} (${uid}): Score ${pData.score} | Grade ${pData.grade}`);
    }
    console.log('------------------------\n');

    // ─── VERIFICATION ASSERTIONS ──────────────────────────────
    log('VERIFY', 'Running strict validation checks...');

    // Assertion 1: Both player drawings exist in drawingsMap
    const p1Data = results.drawings['p1_test_uid'];
    const p2Data = results.drawings['p2_test_uid'];
    if (!p1Data || !p2Data) {
      throw new Error('Verification failed: drawingsMap missing player entries');
    }
    log('VERIFY', '✅ Both player entries found in drawingsMap');

    // Assertion 2: Display names are preserved (not generic "Player")
    if (p1Data.displayName !== 'Player One' || p2Data.displayName !== 'Player Two') {
      throw new Error(`Verification failed: Display names incorrect. p1="${p1Data.displayName}", p2="${p2Data.displayName}"`);
    }
    log('VERIFY', '✅ Display names correctly preserved ("Player One", "Player Two")');

    // Assertion 3: Separate base64 canvas images embedded for both players
    if (!p1Data.imageData || !p1Data.imageData.startsWith('data:image/png;base64,')) {
      throw new Error('Verification failed: Player 1 canvas imageData missing or invalid base64');
    }
    if (!p2Data.imageData || !p2Data.imageData.startsWith('data:image/png;base64,')) {
      throw new Error('Verification failed: Player 2 canvas imageData missing or invalid base64');
    }
    log('VERIFY', '✅ Separate base64 canvas images present for both players');

    // Assertion 4: Winner calculation accuracy
    let expectedWinner = 'tie';
    if (p1Data.score > p2Data.score) expectedWinner = 'p1_test_uid';
    else if (p2Data.score > p1Data.score) expectedWinner = 'p2_test_uid';

    if (results.winnerId !== expectedWinner) {
      throw new Error(`Verification failed: Winner calculation mismatch. Expected "${expectedWinner}", got "${results.winnerId}"`);
    }
    log('VERIFY', `✅ Winner calculation verified: "${results.winnerId}" is the highest scorer`);

    // Assertion 5: Score-consistent feedback (no positive strengths on low/zero scores)
    for (const [uid, pData] of Object.entries(results.drawings)) {
      if (pData.score < 40 || pData.grade === 'F') {
        if (pData.strengths && pData.strengths.length > 0) {
          throw new Error(`Verification failed: Low score player ${uid} has contradictory positive strengths: ${JSON.stringify(pData.strengths)}`);
        }
      }
    }
    log('VERIFY', '✅ Feedback consistency verified: no positive strengths for low/zero scores');

    // Step 8: Test Rematch Flow
    log('REMATCH', 'Player 1 emitting room:rematch...');
    const rematchPromise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Rematch event timeout')), 5000);
      p1Socket.once('room:rematch_ready', (data) => {
        clearTimeout(timer);
        resolve(data);
      });
    });

    p1Socket.emit('room:rematch', { roomCode });
    const rematchData = await rematchPromise;
    log('REMATCH', `✅ Rematch ready confirmed for room: ${rematchData.roomCode}`);

    console.log('\n==================================================');
    console.log('  🎉 ALL MULTIPLAYER E2E TESTS PASSED SUCCESSFULLY');
    console.log('==================================================\n');

  } catch (err) {
    error('TEST_RUNNER', err.message);
    process.exitCode = 1;
  } finally {
    if (p1Socket) p1Socket.disconnect();
    if (p2Socket) p2Socket.disconnect();
  }
}

runTest();
