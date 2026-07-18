import admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';
import env from './env.js';

let db, auth, storage;
let initialized = false;

/**
 * Initialize Firebase Admin SDK.
 * In development without a service account, uses a mock/emulator mode.
 */
export function initializeFirebase() {
  if (initialized) return;

  try {
    if (existsSync(env.firebaseServiceAccountPath)) {
      const serviceAccount = JSON.parse(
        readFileSync(env.firebaseServiceAccountPath, 'utf8')
      );
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: `${serviceAccount.project_id}.appspot.com`,
      });
      console.log('🔥 Firebase Admin initialized with service account');
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      console.log('🔥 Firebase Admin initialized with application default credentials');
    } else {
      console.warn('⚠️  No Firebase credentials found. Running in mock mode.');
      db = new MockFirestore();
      auth = new MockAuth();
      storage = new MockStorage();
      initialized = true;
      return;
    }

    db = admin.firestore();
    auth = admin.auth();
    storage = admin.storage();
    initialized = true;
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error.message);
    // Still set initialized to prevent re-init attempts
    initialized = true;
  }
}

export function getFirestore() {
  if (!initialized) initializeFirebase();
  return db;
}

export function getAuth() {
  if (!initialized) initializeFirebase();
  return auth;
}

export function getStorage() {
  if (!initialized) initializeFirebase();
  return storage;
}

// ─── IN-MEMORY MOCK DATABASE WITH FILE PERSISTENCE ────────────────────
import { writeFileSync } from 'fs';

const DB_FILE = './database.json';
let store = {};

if (existsSync(DB_FILE)) {
  try {
    store = JSON.parse(readFileSync(DB_FILE, 'utf8'));
    console.log(`📦 Loaded database from disk: ${Object.keys(store).length} collections`);
  } catch (err) {
    console.error('❌ Failed to load database file:', err.message);
  }
}

function saveToDisk() {
  try {
    writeFileSync(DB_FILE, JSON.stringify(store, null, 2), 'utf8');
  } catch (err) {
    console.error('❌ Failed to save database to disk:', err.message);
  }
}

class MockFirestoreSnapshot {
  constructor(id, data, exists) {
    this.id = id;
    this._data = data;
    this.exists = exists;
  }
  data() {
    return this._data ? JSON.parse(JSON.stringify(this._data)) : undefined;
  }
}

class MockQuerySnapshot {
  constructor(docs) {
    this.docs = docs;
  }
  get size() {
    return this.docs.length;
  }
}

class MockQuery {
  constructor(collection) {
    this.collection = collection;
    this.filters = [];
    this.orders = [];
    this.limitVal = null;
    this.offsetVal = 0;
  }

  where(field, op, value) {
    this.filters.push({ field, op, value });
    return this;
  }

  orderBy(field, dir = 'asc') {
    this.orders.push({ field, dir });
    return this;
  }

  limit(n) {
    this.limitVal = n;
    return this;
  }

  offset(n) {
    this.offsetVal = n;
    return this;
  }

  count() {
    return {
      get: async () => {
        const res = await this.get();
        return {
          data: () => ({ count: res.size })
        };
      }
    };
  }

  async get() {
    let docs = Object.values(store[this.collection.path] || {}).map(d => ({ ...d }));
    for (const f of this.filters) {
      docs = docs.filter(doc => {
        const val = doc[f.field];
        if (f.op === '==') return val === f.value;
        if (f.op === '>') return val > f.value;
        if (f.op === '<') return val < f.value;
        return true;
      });
    }
    for (const o of this.orders) {
      docs.sort((a, b) => {
        const valA = a[o.field];
        const valB = b[o.field];
        if (valA < valB) return o.dir === 'asc' ? -1 : 1;
        if (valA > valB) return o.dir === 'asc' ? 1 : -1;
        return 0;
      });
    }
    if (this.offsetVal > 0) {
      docs = docs.slice(this.offsetVal);
    }
    if (this.limitVal !== null) {
      docs = docs.slice(0, this.limitVal);
    }
    return new MockQuerySnapshot(docs.map(d => new MockFirestoreSnapshot(d.id, d, true)));
  }
}

class MockCollection {
  constructor(name, parentDoc = null) {
    this.name = name;
    this.parentDoc = parentDoc;
    this.path = parentDoc ? `${parentDoc.path}/${name}` : name;
    if (!store[this.path]) {
      store[this.path] = {};
    }
  }

  doc(id) {
    const docId = id || Math.random().toString(36).substring(2, 12);
    return new MockDocument(docId, this);
  }

  where(field, op, value) {
    return new MockQuery(this).where(field, op, value);
  }

  orderBy(field, dir) {
    return new MockQuery(this).orderBy(field, dir);
  }

  limit(n) {
    return new MockQuery(this).limit(n);
  }

  offset(n) {
    return new MockQuery(this).offset(n);
  }

  async get() {
    const docs = Object.values(store[this.path] || {}).map(data => new MockFirestoreSnapshot(data.id, data, true));
    return new MockQuerySnapshot(docs);
  }
}

class MockDocument {
  constructor(id, collection) {
    this.id = id;
    this.collection = collection;
    this.path = `${collection.path}/${id}`;
  }

  collection(name) {
    return new MockCollection(name, this);
  }

  async get() {
    const data = store[this.collection.path]?.[this.id];
    return new MockFirestoreSnapshot(this.id, data, !!data);
  }

  async set(data) {
    if (!store[this.collection.path]) {
      store[this.collection.path] = {};
    }
    store[this.collection.path][this.id] = { ...data, id: this.id };
    saveToDisk();
    return this;
  }

  async update(data) {
    if (!store[this.collection.path]) {
      store[this.collection.path] = {};
    }
    const existing = store[this.collection.path][this.id] || { id: this.id };
    for (const [key, value] of Object.entries(data)) {
      if (key.includes('.')) {
        const parts = key.split('.');
        let obj = existing;
        for (let i = 0; i < parts.length - 1; i++) {
          obj[parts[i]] = obj[parts[i]] || {};
          obj = obj[parts[i]];
        }
        obj[parts[parts.length - 1]] = value;
      } else {
        existing[key] = value;
      }
    }
    store[this.collection.path][this.id] = existing;
    saveToDisk();
    return this;
  }
}

class MockBatch {
  constructor() {
    this.operations = [];
  }
  set(docRef, data) {
    this.operations.push({ type: 'set', docRef, data });
    return this;
  }
  update(docRef, data) {
    this.operations.push({ type: 'update', docRef, data });
    return this;
  }
  async commit() {
    for (const op of this.operations) {
      if (op.type === 'set') {
        await op.docRef.set(op.data);
      } else if (op.type === 'update') {
        await op.docRef.update(op.data);
      }
    }
    saveToDisk();
  }
}

class MockFirestore {
  collection(name) {
    return new MockCollection(name);
  }
  batch() {
    return new MockBatch();
  }
}

class MockAuth {
  async verifyIdToken(token) {
    if (token === 'mock_token_123') {
      return {
        uid: 'test_user_123',
        email: 'guest@example.com',
        name: 'Guest Player',
      };
    }
    return {
      uid: token.substring(0, 20),
      email: `${token.substring(0, 8)}@example.com`,
      name: `User ${token.substring(0, 4)}`,
    };
  }
}

class MockStorage {
  bucket() {
    return {
      file(name) {
        return {
          async save(buffer, options) {
            return true;
          },
          async getSignedUrl(options) {
            return [`http://localhost:3000/mock-storage/${name}`];
          }
        };
      }
    };
  }
}

export default admin;
