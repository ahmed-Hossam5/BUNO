
import {
  Inject,
  Injectable,
} from '@nestjs/common';

import {
  type Message,
  type Messaging,
  type SendResponse,
} from 'firebase-admin/messaging';

import {
  FIREBASE_MESSAGING,
} from './firebase-admin.provider.js';

// ==========================================
// TYPES
// ==========================================

export interface PushNotificationInput {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface PushTarget {
  deviceId: string;
  token: string;
}

export interface DevicePushResult {
  deviceId: string;
  success: boolean;
  messageId?: string;
  errorCode?: string;
  errorMessage?: string;
  invalidToken: boolean;
}

export interface BatchPushResult {
  successCount: number;
  failureCount: number;
  results: DevicePushResult[];
}

// ==========================================
// CONSTANTS
// ==========================================

const MAX_BATCH_SIZE = 500;

const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

// ==========================================
// FIREBASE MESSAGING SERVICE
// ==========================================

@Injectable()
export class FirebaseMessagingService {
  constructor(
    @Inject(FIREBASE_MESSAGING)
    private readonly messaging: Messaging,
  ) {}

  // ========================================
  // SEND TO ONE DEVICE
  // ========================================

  async sendToDevice(
    target: PushTarget,
    input: PushNotificationInput,
  ): Promise<DevicePushResult> {
    try {
      const messageId = await this.messaging.send(
        this.buildMessage(target.token, input),
      );

      return {
        deviceId: target.deviceId,
        success: true,
        messageId,
        invalidToken: false,
      };
    } catch (error) {
      return this.createFailureResult(
        target.deviceId,
        error,
      );
    }
  }

  // ========================================
  // SEND TO MULTIPLE DEVICES
  // ========================================

  async sendToDevices(
    targets: PushTarget[],
    input: PushNotificationInput,
  ): Promise<BatchPushResult> {
    if (targets.length === 0) {
      return {
        successCount: 0,
        failureCount: 0,
        results: [],
      };
    }

    const results: DevicePushResult[] = [];

    // Process targets in batches of 500

    for (
      let offset = 0;
      offset < targets.length;
      offset += MAX_BATCH_SIZE
    ) {
      const batch = targets.slice(
        offset,
        offset + MAX_BATCH_SIZE,
      );

      const messages = batch.map((target) =>
        this.buildMessage(target.token, input),
      );

      try {
        const response =
          await this.messaging.sendEach(messages);

        response.responses.forEach(
          (sendResponse, index) => {
            const target = batch[index];

            if (!target) {
              return;
            }

            results.push(
              this.mapSendResponse(
                target.deviceId,
                sendResponse,
              ),
            );
          },
        );

      } catch (error) {
        // Entire batch failed

        for (const target of batch) {
          results.push(
            this.createFailureResult(
              target.deviceId,
              error,
            ),
          );
        }
      }
    }

    const successCount = results.filter(
      (result) => result.success,
    ).length;

    return {
      successCount,
      failureCount: results.length - successCount,
      results,
    };
  }

  // ========================================
  // BUILD FIREBASE MESSAGE
  // ========================================

  private buildMessage(
    token: string,
    input: PushNotificationInput,
  ): Message {
    return {
      token,

      notification: {
        title: input.title,
        body: input.body,
      },

      ...(input.data
        ? { data: input.data }
        : {}),

      // Android Configuration
      android: {
        priority: 'high',

        notification: {
          sound: 'default',
        },
      },

      // iOS Configuration
      apns: {
        headers: {
          'apns-priority': '10',
        },

        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };
  }

  // ========================================
  // MAP FIREBASE RESPONSE
  // ========================================

  private mapSendResponse(
    deviceId: string,
    response: SendResponse,
  ): DevicePushResult {
    if (response.success) {
      return {
        deviceId,
        success: true,
        messageId: response.messageId,
        invalidToken: false,
      };
    }

    const errorCode =
      response.error?.code ??
      'messaging/unknown-error';

    return {
      deviceId,
      success: false,
      errorCode,
      errorMessage:
        response.error?.message ??
        'Unknown Firebase Messaging error',
      invalidToken: this.isInvalidToken(errorCode),
    };
  }

  // ========================================
  // HANDLE FAILED REQUEST
  // ========================================

  private createFailureResult(
    deviceId: string,
    error: unknown,
  ): DevicePushResult {
    const errorCode = this.extractErrorCode(error);

    return {
      deviceId,
      success: false,
      errorCode,
      errorMessage:
        error instanceof Error
          ? error.message
          : 'Unknown Firebase Messaging error',
      invalidToken: this.isInvalidToken(errorCode),
    };
  }

  // ========================================
  // EXTRACT FIREBASE ERROR CODE
  // ========================================

  private extractErrorCode(
    error: unknown,
  ): string {
    if (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      typeof error.code === 'string'
    ) {
      return error.code;
    }

    return 'messaging/unknown-error';
  }

  // ========================================
  // CHECK INVALID TOKEN
  // ========================================

  private isInvalidToken(
    errorCode: string,
  ): boolean {
    return INVALID_TOKEN_CODES.has(errorCode);
  }
}
