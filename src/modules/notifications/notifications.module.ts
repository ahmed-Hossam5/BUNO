
import { Module } from '@nestjs/common';

import {
  firebaseMessagingProvider,
} from './firebase/firebase-admin.provider.js';

import {
  FirebaseMessagingService,
} from './firebase/firebase-messaging.service.js';

import {
  NotificationsService,
} from './notifications.service.js';

import {
  NotificationDeliveryWorker,
} from './notification-delivery.worker.js';

@Module({
  providers: [
    firebaseMessagingProvider,
    FirebaseMessagingService,
    NotificationsService,
    NotificationDeliveryWorker,
  ],

  exports: [
    FirebaseMessagingService,
    NotificationsService,
  ],
})
export class NotificationsModule {}
