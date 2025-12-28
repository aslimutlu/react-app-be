import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { appleWebhookSchema } from '../schemas/receipt.schema';
import { handleSubscriptionNotification } from '../services/subscription.service';

interface AppleWebhookBody {
  notification_type: string;
  unified_receipt?: {
    latest_receipt_info?: Array<{
      original_transaction_id?: string;
      expires_date_ms?: string;
      product_id?: string;
    }>;
  };
  bid?: string;
  [key: string]: unknown;
}

export const appleWebhookRoute = async (fastify: FastifyInstance) => {
  fastify.post<{
    Body: AppleWebhookBody;
  }>(
    '/webhook/apple',
    async (request: FastifyRequest<{ Body: AppleWebhookBody }>, reply: FastifyReply) => {
      try {
        // Validate request body
        const validatedData = appleWebhookSchema.parse(request.body);

        const notificationType = validatedData.notification_type;
        fastify.log.info(`Received Apple webhook: ${notificationType}`);

        // Extract user ID and transaction ID from receipt
        // In production, you would need to map the receipt to a user_id
        // For now, we'll log the notification and handle the structure
        const latestReceiptInfo = validatedData.unified_receipt?.latest_receipt_info?.[0];
        const originalTransactionId = latestReceiptInfo?.original_transaction_id;

        // Log notification details
        fastify.log.info({
          notificationType,
          originalTransactionId,
          productId: latestReceiptInfo?.product_id,
          expiresDate: latestReceiptInfo?.expires_date_ms,
        });

        // Handle different notification types
        switch (notificationType) {
          case 'INITIAL_BUY':
            fastify.log.info('Initial purchase detected');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'DID_RENEW':
            fastify.log.info('Subscription renewed');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'DID_FAIL_TO_RENEW':
            fastify.log.info('Subscription renewal failed');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'CANCEL':
            fastify.log.info('Subscription cancelled');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'EXPIRE':
            fastify.log.info('Subscription expired');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'GRACE_PERIOD_EXPIRED':
            fastify.log.info('Grace period expired');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'REFUND':
            fastify.log.info('Subscription refunded');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'REVOKE':
            fastify.log.info('Subscription revoked');
            // In production: Extract userId from receipt and call handleSubscriptionNotification
            break;

          case 'DID_CHANGE_RENEWAL_PREF':
            fastify.log.info('Renewal preference changed');
            break;

          case 'DID_CHANGE_RENEWAL_STATUS':
            fastify.log.info('Renewal status changed');
            break;

          case 'PRICE_INCREASE':
            fastify.log.info('Price increase notification');
            break;

          case 'RENEWAL_EXTENDED':
            fastify.log.info('Renewal extended');
            break;

          case 'RENEWAL_EXTENSION':
            fastify.log.info('Renewal extension');
            break;

          default:
            fastify.log.warn(`Unknown notification type: ${notificationType}`);
        }

        // In production, you would:
        // 1. Extract userId from the receipt (you might need to store receipt -> userId mapping)
        // 2. Call handleSubscriptionNotification(userId, notificationType, originalTransactionId)

        return reply.status(200).send({
          success: true,
          message: 'Webhook processed',
        });
      } catch (error) {
        if (error instanceof Error) {
          fastify.log.error(`Apple webhook error: ${error.message}`);
          return reply.status(400).send({
            success: false,
            error: error.message,
          });
        }

        fastify.log.error('Unknown error in Apple webhook');
        return reply.status(500).send({
          success: false,
          error: 'Internal server error',
        });
      }
    }
  );
};

