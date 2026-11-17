
import {
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import {
  and,
  asc,
  desc,
  eq,
  inArray,
  lte,
  or,
  sql,
} from 'drizzle-orm';

import {
  notifications,
  notificationTypeEnum,
} from '../../database/schema/notifications.schema.js';

import {
  userDevices,
} from '../../database/schema/user-devices.schema.js';

import {
  notificationDeliveries,
} from '../../database/schema/notification-deliveries.schema.js';

import {
  DATABASE_CONNECTION,
} from '../../database/database.constants.js';

import type {
  databaseProvider,
} from '../../database/database.provider.js';

import {
  FirebaseMessagingService,
} from './firebase/firebase-messaging.service.js';

// ==========================================
// DATABASE CONNECTION TYPE
// ==========================================

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

// ==========================================
// TYPES
// ==========================================

type NotificationType =
  (typeof notificationTypeEnum.enumValues)[number];

export interface CreateNotificationInput {
  userId: string;

  type: NotificationType;

  title: string;

  message: string;

  data?: Record<string, string>;
}

interface ClaimedDelivery {
  deliveryId: string;
  attemptCount: number;
  maxAttempts: number;

  deviceId: string;
  fcmToken: string;
  deviceIsActive: boolean;

  title: string;
  message: string;
  notificationData: unknown;
}

type DeliveryOutcome =
  | 'SENT'
  | 'RETRY_SCHEDULED'
  | 'FAILED'
  | 'CANCELLED';

// ==========================================
// NOTIFICATIONS SERVICE
// ==========================================

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(
    NotificationsService.name,
  );

  private readonly DELIVERY_LEASE_MS = 120_000;

  private readonly MAX_PROCESSING_BATCH = 50;

  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,

    private readonly firebaseMessagingService: FirebaseMessagingService,
  ) {}

  // ==========================================
  // 1. CREATE NOTIFICATION
  // ==========================================

  async createForUser(
    input: CreateNotificationInput,
  ) {
    return this.connection.db.transaction(
      async (tx) => {

        // Create notification record

        const [notification] = await tx
          .insert(notifications)
          .values({
            userId: input.userId,
            type: input.type,
            title: input.title,
            message: input.message,
            data: input.data ?? null,
          })
          .returning();

        if (!notification) {
          throw new Error(
            'Failed to create notification',
          );
        }

        // Get active user devices

        const devices = await tx
          .select({
            id: userDevices.id,
          })
          .from(userDevices)
          .where(
            and(
              eq(userDevices.userId, input.userId),
              eq(userDevices.isActive, true),
            ),
          );

        // Create one delivery per device

        if (devices.length > 0) {
          await tx
            .insert(notificationDeliveries)
            .values(
              devices.map((device) => ({
                notificationId: notification.id,
                userDeviceId: device.id,
              })),
            );
        }

        return {
          notification,
          deliveriesCreated: devices.length,
        };
      },
    );
  }

  // ==========================================
  // 2. GET USER NOTIFICATIONS
  // ==========================================

  async findByUser(
    userId: string,
    limit = 20,
  ) {
    const safeLimit = Number.isFinite(limit)
      ? Math.min(
          Math.max(Math.trunc(limit), 1),
          100,
        )
      : 20;

    return this.connection.db
      .select()
      .from(notifications)
      .where(
        eq(notifications.userId, userId),
      )
      .orderBy(
        desc(notifications.createdAt),
      )
      .limit(safeLimit);
  }

  // ==========================================
  // 3. MARK NOTIFICATION AS READ
  // ==========================================

  async markAsRead(
    userId: string,
    notificationId: string,
  ) {
    const now = new Date();

    const [updated] = await this.connection.db
      .update(notifications)
      .set({
        isRead: true,
        readAt: now,
      })
      .where(
        and(
          eq(notifications.id, notificationId),
          eq(notifications.userId, userId),
        ),
      )
      .returning();

    if (!updated) {
      throw new NotFoundException(
        'Notification not found',
      );
    }

    return updated;
  }

  // ==========================================
  // 4. PROCESS PENDING DELIVERIES
  // ==========================================

  async processPendingDeliveries(
    batchSize = 25,
  ) {
    const safeBatchSize = Math.min(
      Math.max(Math.trunc(batchSize), 1),
      this.MAX_PROCESSING_BATCH,
    );

    // Claim deliveries atomically

    const deliveries =
      await this.claimPendingDeliveries(
        safeBatchSize,
      );

    if (deliveries.length === 0) {
      return {
        claimed: 0,
        sent: 0,
        retryScheduled: 0,
        failed: 0,
        cancelled: 0,
        processingErrors: 0,
      };
    }

    // Process independently

    const results = await Promise.allSettled(
      deliveries.map((delivery) =>
        this.deliverOne(delivery),
      ),
    );

    const summary = {
      claimed: deliveries.length,
      sent: 0,
      retryScheduled: 0,
      failed: 0,
      cancelled: 0,
      processingErrors: 0,
    };

    for (const result of results) {
      if (result.status === 'rejected') {
        summary.processingErrors++;

        this.logger.error(
          'Delivery processing failed',
          result.reason instanceof Error
            ? result.reason.stack
            : String(result.reason),
        );

        continue;
      }

      switch (result.value) {
        case 'SENT':
          summary.sent++;
          break;

        case 'RETRY_SCHEDULED':
          summary.retryScheduled++;
          break;

        case 'FAILED':
          summary.failed++;
          break;

        case 'CANCELLED':
          summary.cancelled++;
          break;
      }
    }

    return summary;
  }

  // ==========================================
  // 5. CLAIM PENDING DELIVERIES
  // ==========================================

  private async claimPendingDeliveries(
    batchSize: number,
  ): Promise<ClaimedDelivery[]> {
    const now = new Date();

    const lockedUntil = new Date(
      now.getTime() + this.DELIVERY_LEASE_MS,
    );

    return this.connection.db.transaction(
      async (tx) => {

        // Mark exhausted expired deliveries as FAILED

        await tx
          .update(notificationDeliveries)
          .set({
            status: 'FAILED',
            failedAt: now,
            lockedUntil: null,
            lastErrorCode: 'DELIVERY_ATTEMPTS_EXHAUSTED',
            lastErrorMessage:
              'Maximum delivery attempts reached.',
            updatedAt: now,
          })
          .where(
            and(
              eq(
                notificationDeliveries.status,
                'PROCESSING',
              ),
              lte(
                notificationDeliveries.lockedUntil,
                now,
              ),
              sql`${notificationDeliveries.attemptCount} >= ${notificationDeliveries.maxAttempts}`,
            ),
          );

        // Also clean exhausted PENDING records

        await tx
          .update(notificationDeliveries)
          .set({
            status: 'FAILED',
            failedAt: now,
            lockedUntil: null,
            lastErrorCode: 'DELIVERY_ATTEMPTS_EXHAUSTED',
            lastErrorMessage:
              'Maximum delivery attempts reached.',
            updatedAt: now,
          })
          .where(
            and(
              eq(
                notificationDeliveries.status,
                'PENDING',
              ),
              sql`${notificationDeliveries.attemptCount} >= ${notificationDeliveries.maxAttempts}`,
            ),
          );

        // Find eligible deliveries

        const candidates = await tx
          .select({
            id: notificationDeliveries.id,
          })
          .from(notificationDeliveries)
          .where(
            or(
              and(
                eq(
                  notificationDeliveries.status,
                  'PENDING',
                ),
                lte(
                  notificationDeliveries.nextAttemptAt,
                  now,
                ),
                sql`${notificationDeliveries.attemptCount} < ${notificationDeliveries.maxAttempts}`,
              ),

              and(
                eq(
                  notificationDeliveries.status,
                  'PROCESSING',
                ),
                lte(
                  notificationDeliveries.lockedUntil,
                  now,
                ),
                sql`${notificationDeliveries.attemptCount} < ${notificationDeliveries.maxAttempts}`,
              ),
            ),
          )
          .orderBy(
            asc(notificationDeliveries.nextAttemptAt),
            asc(notificationDeliveries.createdAt),
          )
          .limit(batchSize)
          .for('update', {
            skipLocked: true,
          });

        if (candidates.length === 0) {
          return [];
        }

        const ids = candidates.map(
          (item) => item.id,
        );

        // Claim selected records

        await tx
          .update(notificationDeliveries)
          .set({
            status: 'PROCESSING',

            attemptCount: sql`
              ${notificationDeliveries.attemptCount} + 1
            `,

            lastAttemptAt: now,

            lockedUntil,

            updatedAt: now,
          })
          .where(
            inArray(
              notificationDeliveries.id,
              ids,
            ),
          );

        // Load notification and device information

        return tx
          .select({
            deliveryId: notificationDeliveries.id,

            attemptCount:
              notificationDeliveries.attemptCount,

            maxAttempts:
              notificationDeliveries.maxAttempts,

            deviceId: userDevices.id,

            fcmToken: userDevices.fcmToken,

            deviceIsActive: userDevices.isActive,

            title: notifications.title,

            message: notifications.message,

            notificationData: notifications.data,
          })
          .from(notificationDeliveries)
          .innerJoin(
            notifications,
            eq(
              notificationDeliveries.notificationId,
              notifications.id,
            ),
          )
          .innerJoin(
            userDevices,
            eq(
              notificationDeliveries.userDeviceId,
              userDevices.id,
            ),
          )
          .where(
            inArray(
              notificationDeliveries.id,
              ids,
            ),
          );
      },
    );
  }

  // ==========================================
  // 6. SEND ONE DELIVERY
  // ==========================================

  private async deliverOne(
    delivery: ClaimedDelivery,
  ): Promise<DeliveryOutcome> {

    // Device may have been deactivated
    // after the delivery was created.

    if (!delivery.deviceIsActive) {
      await this.connection.db
        .update(notificationDeliveries)
        .set({
          status: 'CANCELLED',
          lockedUntil: null,
          updatedAt: new Date(),
        })
        .where(
          eq(
            notificationDeliveries.id,
            delivery.deliveryId,
          ),
        );

      return 'CANCELLED';
    }

    const result =
      await this.firebaseMessagingService.sendToDevice(
        {
          deviceId: delivery.deviceId,
          token: delivery.fcmToken,
        },
        {
          title: delivery.title,
          body: delivery.message,
          data: this.toFcmData(
            delivery.notificationData,
          ),
        },
      );

    const now = new Date();

    // ========================================
    // SUCCESS
    // ========================================

    if (result.success) {
      await this.connection.db
        .update(notificationDeliveries)
        .set({
          status: 'SENT',
          sentAt: now,
          lockedUntil: null,
          lastErrorCode: null,
          lastErrorMessage: null,
          updatedAt: now,
        })
        .where(
          eq(
            notificationDeliveries.id,
            delivery.deliveryId,
          ),
        );

      return 'SENT';
    }

    // ========================================
    // INVALID TOKEN
    // ========================================

    if (result.invalidToken) {
      await this.connection.db.transaction(
        async (tx) => {

          // Deactivate invalid device

          await tx
            .update(userDevices)
            .set({
              isActive: false,
              updatedAt: now,
            })
            .where(
              eq(
                userDevices.id,
                delivery.deviceId,
              ),
            );

          // Mark delivery as permanently failed

          await tx
            .update(notificationDeliveries)
            .set({
              status: 'FAILED',
              failedAt: now,
              lockedUntil: null,
              lastErrorCode: result.errorCode,
              lastErrorMessage: result.errorMessage,
              updatedAt: now,
            })
            .where(
              eq(
                notificationDeliveries.id,
                delivery.deliveryId,
              ),
            );
        },
      );

      return 'FAILED';
    }

    // ========================================
    // RETRY OR FINAL FAILURE
    // ========================================

    const exhausted =
      delivery.attemptCount >= delivery.maxAttempts;

    const nextAttemptAt = exhausted
      ? null
      : this.calculateNextRetry(
          delivery.attemptCount,
        );

    await this.connection.db
      .update(notificationDeliveries)
      .set({
        status: exhausted
          ? 'FAILED'
          : 'PENDING',

        failedAt: exhausted ? now : null,

        nextAttemptAt:
          nextAttemptAt ?? now,

        lockedUntil: null,

        lastErrorCode:
          result.errorCode ??
          'messaging/unknown-error',

        lastErrorMessage:
          result.errorMessage ??
          'Unknown Firebase error',

        updatedAt: now,
      })
      .where(
        eq(
          notificationDeliveries.id,
          delivery.deliveryId,
        ),
      );

    return exhausted
      ? 'FAILED'
      : 'RETRY_SCHEDULED';
  }

  // ==========================================
  // 7. EXPONENTIAL BACKOFF
  // ==========================================

  private calculateNextRetry(
    attemptCount: number,
  ): Date {
    const baseDelay = 5_000;

    const maxDelay = 15 * 60 * 1000;

    const exponent = Math.max(
      0,
      attemptCount - 1,
    );

    const delay = Math.min(
      maxDelay,
      baseDelay * Math.pow(2, exponent),
    );

    // Add random jitter to avoid
    // simultaneous retry bursts.

    const jitter = 0.8 + Math.random() * 0.4;

    return new Date(
      Date.now() + Math.round(delay * jitter),
    );
  }

  // ==========================================
  // 8. CONVERT JSON DATA TO FCM DATA
  // ==========================================

  private toFcmData(
    value: unknown,
  ): Record<string, string> | undefined {
    if (
      !value ||
      typeof value !== 'object' ||
      Array.isArray(value)
    ) {
      return undefined;
    }

    const entries = Object.entries(
      value as Record<string, unknown>,
    );

    return Object.fromEntries(
      entries
        .filter(
          ([, item]) =>
            item !== null &&
            item !== undefined,
        )
        .map(([key, item]) => [
          key,
          typeof item === 'string'
            ? item
            : typeof item === 'object'
              ? JSON.stringify(item) ?? ''
              : String(item),
        ]),
    );
  }
}
