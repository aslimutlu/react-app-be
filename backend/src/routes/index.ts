import { FastifyInstance } from 'fastify';
import { verifyReceiptRoute } from './verify-receipt';
import { appleWebhookRoute } from './apple-webhook';

export const registerRoutes = async (fastify: FastifyInstance) => {
  await fastify.register(verifyReceiptRoute);
  await fastify.register(appleWebhookRoute);
};

