"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const admin = require("firebase-admin");
const fs = require("node:fs/promises");
const path = require("node:path");
function chunk(arr, size) {
    const out = [];
    for (let i = 0; i < arr.length; i += size)
        out.push(arr.slice(i, i + size));
    return out;
}
function extractEmoji(name) {
    // Most entries are "⚽ Football/Soccer". Take the first token if it’s non-ascii-ish.
    const first = name.trim().split(/\s+/)[0];
    if (!first)
        return null;
    return first.length <= 4 ? first : null;
}
async function seedCategories(db) {
    const categoriesPath = path.resolve(__dirname, '../../seed/categories.json');
    const raw = await fs.readFile(categoriesPath, 'utf8');
    const categories = JSON.parse(raw);
    console.log(`Seeding categories (${categories.length})…`);
    for (const group of chunk(categories, 400)) {
        const batch = db.batch();
        for (const c of group) {
            // Deterministic doc id to keep seeding idempotent.
            const id = c.categoryName
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, '-')
                .replace(/(^-|-$)/g, '')
                .slice(0, 120);
            const ref = db.collection('categories').doc(id);
            batch.set(ref, {
                categoryId: id,
                categoryName: c.categoryName,
                categoryNameEt: null,
                categoryNameRu: null,
                icon: extractEmoji(c.categoryName),
                isActive: true,
                sortOrder: c.sortOrder,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        await batch.commit();
    }
}
async function seedDemoActivities(db) {
    const activitiesSnap = await db.collection('activities').limit(1).get();
    if (!activitiesSnap.empty) {
        console.log('Skipping demo activities (activities already exist).');
        return;
    }
    const now = Date.now();
    const demo = [
        {
            title: 'Swimming for Beginners',
            category: '🏊 Swimming',
            city: 'Tallinn',
            ageRangeMin: 4,
            ageRangeMax: 10,
            priceAmount: 15,
            priceType: 'per_session',
        },
        {
            title: 'Kids Coding Club',
            category: '💻 Coding & Programming',
            city: 'Tartu',
            ageRangeMin: 8,
            ageRangeMax: 14,
            priceAmount: 59,
            priceType: 'monthly',
        },
        {
            title: 'Art Studio: Painting',
            category: '🎨 Painting & Drawing',
            city: 'Pärnu',
            ageRangeMin: 5,
            ageRangeMax: 12,
            priceAmount: 12,
            priceType: 'per_session',
        },
        {
            title: 'Forest School (Outdoor)',
            category: '🌲 Forest School',
            city: 'Tallinn',
            ageRangeMin: 3,
            ageRangeMax: 7,
            priceAmount: 0,
            priceType: 'free',
        },
        {
            title: 'Piano Lessons (Starter)',
            category: '🎹 Piano Lessons',
            city: 'Tartu',
            ageRangeMin: 6,
            ageRangeMax: 12,
            priceAmount: 20,
            priceType: 'per_session',
        },
        {
            title: 'Martial Arts Basics',
            category: '🥋 Martial Arts (Judo, Karate, Taekwondo)',
            city: 'Pärnu',
            ageRangeMin: 7,
            ageRangeMax: 15,
            priceAmount: 45,
            priceType: 'monthly',
        },
        {
            title: 'Robotics: Build & Play',
            category: '🤖 Robotics',
            city: 'Tallinn',
            ageRangeMin: 9,
            ageRangeMax: 16,
            priceAmount: 80,
            priceType: 'term',
        },
        {
            title: 'Chess for Kids',
            category: '🧠 Chess',
            city: 'Tartu',
            ageRangeMin: 6,
            ageRangeMax: 13,
            priceAmount: 10,
            priceType: 'per_session',
        },
        {
            title: 'Ballet (Beginner)',
            category: '💃 Ballet',
            city: 'Tallinn',
            ageRangeMin: 4,
            ageRangeMax: 9,
            priceAmount: 50,
            priceType: 'monthly',
        },
        {
            title: 'Photography Basics',
            category: '📸 Photography',
            city: 'Pärnu',
            ageRangeMin: 10,
            ageRangeMax: 16,
            priceAmount: 25,
            priceType: 'per_session',
        },
    ];
    console.log(`Seeding demo activities (${demo.length})…`);
    for (const group of chunk([...demo], 400)) {
        const batch = db.batch();
        group.forEach((d, i) => {
            const ref = db.collection('activities').doc();
            batch.set(ref, {
                activityId: ref.id,
                providerUserId: `demo_provider_${i + 1}`,
                providerBusinessName: `Demo Provider ${i + 1}`,
                title: d.title,
                description: 'Demo listing created for UI preview. Replace with real provider content later.',
                category: d.category,
                subCategory: null,
                ageRangeMin: d.ageRangeMin,
                ageRangeMax: d.ageRangeMax,
                city: d.city,
                address: 'Demo address',
                locationName: 'Demo location',
                priceAmount: d.priceAmount,
                priceCurrency: 'EUR',
                priceType: d.priceType,
                priceNotes: null,
                scheduleType: 'weekly',
                scheduleDetails: 'Mon/Wed 17:00-18:00 (demo)',
                startDate: null,
                endDate: null,
                photos: [],
                videoUrl: null,
                languages: ['Estonian', 'English', 'Russian'],
                maxParticipants: null,
                createdAt: admin.firestore.Timestamp.fromMillis(now - i * 86_400_000),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                isActive: true,
                approvalStatus: 'approved',
                rejectionReason: null,
                viewCount: 0,
                inquiryCount: 0,
            });
        });
        await batch.commit();
    }
}
async function main() {
    const projectId = process.env.FIREBASE_PROJECT_ID ||
        process.env.GCLOUD_PROJECT ||
        process.env.GOOGLE_CLOUD_PROJECT ||
        '';
    if (!projectId) {
        throw new Error([
            'Missing project id.',
            'Set FIREBASE_PROJECT_ID (recommended) or GOOGLE_CLOUD_PROJECT.',
            'Example:',
            '  FIREBASE_PROJECT_ID=kidsactivities-389e1 npm run seed:full',
            '',
            'Also ensure firebase-admin credentials are available:',
            '  export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/serviceAccountKey.json"',
        ].join('\n'));
    }
    admin.initializeApp({ projectId });
    const db = admin.firestore();
    await seedCategories(db);
    await seedDemoActivities(db);
    console.log('Seed complete.');
}
main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});
//# sourceMappingURL=seed_full.js.map