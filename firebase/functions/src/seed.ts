import * as admin from 'firebase-admin';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';

async function main() {
  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    '';

  if (!projectId) {
    throw new Error(
      [
        'Missing project id.',
        'Set FIREBASE_PROJECT_ID (recommended) or GOOGLE_CLOUD_PROJECT.',
        'Example:',
        '  FIREBASE_PROJECT_ID=kidsactivities-389e1 npm run seed:categories',
        '',
        'Also ensure firebase-admin credentials are available:',
        '  export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/serviceAccountKey.json"',
      ].join('\n'),
    );
  }

  admin.initializeApp({ projectId });
  const db = admin.firestore();

  const categoriesPath = path.resolve(__dirname, '../../seed/categories.json');
  const raw = await fs.readFile(categoriesPath, 'utf8');
  const categories: Array<{ categoryName: string; sortOrder: number }> = JSON.parse(raw);

  console.log(`Seeding ${categories.length} categories…`);
  const batch = db.batch();
  for (const c of categories) {
    const ref = db.collection('categories').doc();
    batch.set(ref, {
      categoryName: c.categoryName,
      categoryNameEt: null,
      categoryNameRu: null,
      icon: null,
      isActive: true,
      sortOrder: c.sortOrder,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

