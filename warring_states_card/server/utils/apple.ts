const APPLE_PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
const APPLE_BUNDLE_ID = process.env.APPLE_BUNDLE_ID || 'com.game.Warringstates';
const APPLE_SHARED_SECRET = process.env.APPLE_SHARED_SECRET || '';

export type ApplePurchase = {
  productId: string;
  transactionId: string;
  quantity: number;
  environment?: string;
};

type AppleResponse = {
  status?: number;
  environment?: string;
  receipt?: {
    bundle_id?: string;
    in_app?: Array<Record<string, string>>;
  };
  latest_receipt_info?: Array<Record<string, string>>;
};

async function verifyAt(url: string, receipt: string): Promise<AppleResponse> {
  const body: Record<string, unknown> = {
    'receipt-data': receipt,
    'exclude-old-transactions': true,
  };
  if (APPLE_SHARED_SECRET) body.password = APPLE_SHARED_SECRET;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error(`Apple verification HTTP ${response.status}`);
  return await response.json() as AppleResponse;
}

/**
 * Verify an App Store receipt. Production is tried first; 21007 switches to
 * Apple's sandbox endpoint. The server, not the client, selects the credit.
 */
export async function verifyApplePurchase(
  receipt: string,
  expectedProductId: string,
  expectedTransactionId?: string,
): Promise<ApplePurchase | { error: string }> {
  if (!receipt.trim()) return { error: 'Missing Apple receipt' };

  let result = await verifyAt(APPLE_PRODUCTION_URL, receipt);
  if (result.status === 21007) {
    result = await verifyAt(APPLE_SANDBOX_URL, receipt);
  }
  if (result.status !== 0) return { error: `Apple receipt status ${result.status ?? 'unknown'}` };
  if (result.receipt?.bundle_id !== APPLE_BUNDLE_ID) {
    return { error: 'Apple bundle ID mismatch' };
  }

  const transactions = [
    ...(result.receipt?.in_app ?? []),
    ...(result.latest_receipt_info ?? []),
  ];
  const matches = transactions.filter((item) =>
    item.product_id === expectedProductId &&
    (!expectedTransactionId || item.transaction_id === expectedTransactionId),
  );
  const transaction = matches.sort((a, b) =>
    Number(b.purchase_date_ms || 0) - Number(a.purchase_date_ms || 0),
  )[0];

  if (!transaction?.transaction_id) return { error: 'Apple product transaction not found' };
  const quantity = Number(transaction.quantity || 1);
  if (!Number.isInteger(quantity) || quantity !== 1) return { error: 'Invalid Apple quantity' };

  return {
    productId: transaction.product_id,
    transactionId: transaction.transaction_id,
    quantity,
    environment: result.environment,
  };
}
