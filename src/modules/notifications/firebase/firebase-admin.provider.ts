
import {
  Provider,
} from '@nestjs/common';

import { ConfigService } from '@nestjs/config';

import { existsSync } from 'node:fs';

import {
  applicationDefault,
  getApps,
  initializeApp,
} from 'firebase-admin/app';

import {
  getMessaging,
  type Messaging,
} from 'firebase-admin/messaging';

// ==========================================
// FIREBASE MESSAGING INJECTION TOKEN
// ==========================================

export const FIREBASE_MESSAGING = 'FIREBASE_MESSAGING';

// ==========================================
// FIREBASE ADMIN PROVIDER
// ==========================================

export const firebaseMessagingProvider: Provider = {
  provide: FIREBASE_MESSAGING,

  inject: [ConfigService],

  useFactory: (
    configService: ConfigService,
  ): Messaging => {
    const projectId = configService.get<string>(
      'FIREBASE_PROJECT_ID',
    );

    const credentialsPath = configService.get<string>(
      'GOOGLE_APPLICATION_CREDENTIALS',
    );

    // Validate Firebase Project ID

    if (!projectId) {
      throw new Error(
        'FIREBASE_PROJECT_ID is not configured',
      );
    }

    // Validate Service Account Path

    if (!credentialsPath) {
      throw new Error(
        'GOOGLE_APPLICATION_CREDENTIALS is not configured',
      );
    }

    // Ensure Service Account File Exists

    if (!existsSync(credentialsPath)) {
      throw new Error(
        'Firebase Service Account JSON file not found',
      );
    }

    // Reuse Existing Firebase App

    const existingApp = getApps().find(
      (app) => app.name === 'buno-notifications',
    );

    const firebaseApp =
      existingApp ??
      initializeApp(
        {
          credential: applicationDefault(),
          projectId,
        },
        'buno-notifications',
      );

    // Return Firebase Cloud Messaging

    return getMessaging(firebaseApp);
  },
};
