import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { verifyReceiptSchema } from '../schemas/receipt.schema';
import {
  mockAppleValidation,
  updateUserPremiumStatus,
  upsertSubscription,
} from '../services/subscription.service';

interface VerifyReceiptBody {
  userId: string;
  receiptData: string;
  productId: string;
}

export const verifyReceiptRoute = async (fastify: FastifyInstance) => {
  fastify.post<{
    Body: VerifyReceiptBody;
  }>(
    '/api/verify-receipt',
    async (request: FastifyRequest<{ Body: VerifyReceiptBody }>, reply: FastifyReply) => {
      try {
        // Validate request body
        const validatedData = verifyReceiptSchema.parse(request.body);

        // Mock Apple receipt validation
        const validationResult = await mockAppleValidation(
          validatedData.receiptData,
          validatedData.productId
        );

        if (!validationResult.isValid) {
          return reply.status(400).send({
            success: false,
            error: 'Invalid receipt',
          });
        }

        // Determine plan type from productId (assuming naming convention)
        const planType: 'monthly' | 'yearly' =
          validatedData.productId.includes('yearly') || validatedData.productId.includes('annual')
            ? 'yearly'
            : 'monthly';

        // Calculate subscription expiry date
        const expiryDate = validationResult.expiresDate
          ? new Date(validationResult.expiresDate)
          : new Date(Date.now() + (planType === 'yearly' ? 365 : 30) * 24 * 60 * 60 * 1000);

        // Update user premium status
        await updateUserPremiumStatus(validatedData.userId, true, expiryDate);

        // Create subscription record
        await upsertSubscription({
          userId: validatedData.userId,
          originalTransactionId: validationResult.originalTransactionId,
          status: 'active',
          planType,
        });

        return reply.status(200).send({
          success: true,
          data: {
            originalTransactionId: validationResult.originalTransactionId,
            isPremium: true,
            subscriptionExpiry: expiryDate.toISOString(),
          },
        });
      } catch (error) {
        if (error instanceof Error) {
          fastify.log.error(`Verify receipt error: ${error.message}`);
          return reply.status(500).send({
            success: false,
            error: error.message,
          });
        }

        fastify.log.error('Unknown error in verify receipt');
        return reply.status(500).send({
          success: false,
          error: 'Internal server error',
        });
      }
    }
  );
};

