import { getSupabaseClient } from '../lib/supabase';

interface UpdateSubscriptionParams {
  userId: string;
  originalTransactionId: string;
  status: 'active' | 'expired' | 'grace_period';
  planType: 'monthly' | 'yearly';
}

interface MockAppleValidationResult {
  isValid: boolean;
  originalTransactionId: string;
  productId: string;
  expiresDate?: number;
}

/**
 * Mock Apple receipt validation
 * In production, this should call Apple's verifyReceipt API
 */
export const mockAppleValidation = async (
  receiptData: string,
  productId: string
): Promise<MockAppleValidationResult> => {
  // Simulate API call delay
  await new Promise((resolve) => setTimeout(resolve, 100));

  // Mock validation - in production, replace with actual Apple API call
  // For now, we'll generate a mock transaction ID
  const mockTransactionId = `mock_${Date.now()}_${Math.random().toString(36).substring(7)}`;

  return {
    isValid: true,
    originalTransactionId: mockTransactionId,
    productId,
    expiresDate: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30 days from now
  };
};

/**
 * Update user's premium status in profiles table
 */
export const updateUserPremiumStatus = async (
  userId: string,
  isPremium: boolean,
  subscriptionExpiry?: Date
): Promise<void> => {
  const supabase = getSupabaseClient();

  const updateData: {
    is_premium: boolean;
    subscription_expiry?: string;
  } = {
    is_premium: isPremium,
  };

  if (subscriptionExpiry) {
    updateData.subscription_expiry = subscriptionExpiry.toISOString();
  }

  const { error } = await supabase
    .from('profiles')
    .update(updateData)
    .eq('id', userId);

  if (error) {
    throw new Error(`Failed to update user premium status: ${error.message}`);
  }
};

/**
 * Create or update subscription record
 */
export const upsertSubscription = async (
  params: UpdateSubscriptionParams
): Promise<void> => {
  const supabase = getSupabaseClient();

  // Check if subscription already exists
  const { data: existingSubscription } = await supabase
    .from('subscriptions')
    .select('id')
    .eq('original_transaction_id', params.originalTransactionId)
    .single();

  if (existingSubscription) {
    // Update existing subscription
    const { error } = await supabase
      .from('subscriptions')
      .update({
        status: params.status,
        plan_type: params.planType,
        updated_at: new Date().toISOString(),
      })
      .eq('original_transaction_id', params.originalTransactionId);

    if (error) {
      throw new Error(`Failed to update subscription: ${error.message}`);
    }
  } else {
    // Create new subscription
    const { error } = await supabase.from('subscriptions').insert({
      user_id: params.userId,
      original_transaction_id: params.originalTransactionId,
      status: params.status,
      plan_type: params.planType,
    });

    if (error) {
      throw new Error(`Failed to create subscription: ${error.message}`);
    }
  }
};

/**
 * Handle subscription status based on notification type
 */
export const handleSubscriptionNotification = async (
  userId: string,
  notificationType: string,
  originalTransactionId?: string
): Promise<void> => {
  const supabase = getSupabaseClient();

  switch (notificationType) {
    case 'INITIAL_BUY':
    case 'DID_RENEW':
    case 'RENEWAL_EXTENDED':
    case 'RENEWAL_EXTENSION':
      await updateUserPremiumStatus(userId, true);
      if (originalTransactionId) {
        await upsertSubscription({
          userId,
          originalTransactionId,
          status: 'active',
          planType: 'monthly', // Default, should be determined from receipt
        });
      }
      break;

    case 'CANCEL':
    case 'DID_CHANGE_RENEWAL_STATUS':
      // User cancelled but subscription is still active until expiry
      if (originalTransactionId) {
        await upsertSubscription({
          userId,
          originalTransactionId,
          status: 'grace_period',
          planType: 'monthly',
        });
      }
      break;

    case 'EXPIRE':
    case 'DID_FAIL_TO_RENEW':
    case 'GRACE_PERIOD_EXPIRED':
      await updateUserPremiumStatus(userId, false);
      if (originalTransactionId) {
        await upsertSubscription({
          userId,
          originalTransactionId,
          status: 'expired',
          planType: 'monthly',
        });
      }
      break;

    case 'REFUND':
    case 'REVOKE':
      await updateUserPremiumStatus(userId, false);
      if (originalTransactionId) {
        await upsertSubscription({
          userId,
          originalTransactionId,
          status: 'expired',
          planType: 'monthly',
        });
      }
      break;

    default:
      console.log(`Unhandled notification type: ${notificationType}`);
  }
};

