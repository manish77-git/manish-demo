import dotenv from 'dotenv';
dotenv.config({ path: './backend/.env' });

console.log('GROQ_API_KEY:', process.env.GROQ_API_KEY ? 'Present' : 'Missing');
console.log('GEMINI_API_KEY:', process.env.GEMINI_API_KEY ? 'Present' : 'Missing');

async function testGroq() {
  console.log('\n--- Testing Groq (llama-3.2-11b-vision-preview) ---');
  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.2-11b-vision-preview',
        messages: [{ role: 'user', content: 'Say OK' }],
      }),
    });
    console.log('Groq status:', res.status);
    const data = await res.json();
    console.log('Groq response:', JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Groq error:', err.message);
  }
}

async function testGemini() {
  console.log('\n--- Testing Gemini (gemini-1.5-flash) ---');
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: 'Say OK' }] }],
      }),
    });
    console.log('Gemini status:', res.status);
    const data = await res.json();
    console.log('Gemini response:', JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Gemini error:', err.message);
  }
}

async function run() {
  await testGroq();
  await testGemini();
}

run();
