import { z } from 'zod';

export const verifyReceiptSchema = z.object({
  userId: z.string().uuid('userId must be a valid UUID'),
  receiptData: z.string().min(1, 'receiptData is required'),
  productId: z.string().min(1, 'productId is required'),
});

export type VerifyReceiptRequest = z.infer<typeof verifyReceiptSchema>;

export const appleWebhookSchema = z.object({
  notification_type: z.enum([
    'INITIAL_BUY',
    'DID_RENEW',
    'DID_FAIL_TO_RENEW',
    'DID_CHANGE_RENEWAL_PREF',
    'DID_CHANGE_RENEWAL_STATUS',
    'CANCEL',
    'EXPIRE',
    'GRACE_PERIOD_EXPIRED',
    'REFUND',
    'REVOKE',
    'PRICE_INCREASE',
    'RENEWAL_EXTENDED',
    'RENEWAL_EXTENSION',
  ]),
  unified_receipt: z.object({
    latest_receipt_info: z.array(z.any()).optional(),
    latest_receipt: z.string().optional(),
    status: z.number().optional(),
  }),
  bid: z.string().optional(),
  bvrs: z.string().optional(),
  environment: z.enum(['Sandbox', 'Production']).optional(),
  auto_renew_status: z.boolean().optional(),
  auto_renew_status_change_date: z.string().optional(),
  auto_renew_status_change_date_ms: z.string().optional(),
  auto_renew_status_change_date_pst: z.string().optional(),
  latest_expired_receipt_info: z.any().optional(),
  latest_receipt: z.string().optional(),
  latest_receipt_info: z.array(z.any()).optional(),
  pending_renewal_info: z.array(z.any()).optional(),
  notification_type: z.string().optional(),
  password: z.string().optional(),
  unified_receipt: z.any().optional(),
});

export type AppleWebhookRequest = z.infer<typeof appleWebhookSchema>;

