/*
  # Add piece_id to stripe_orders table

  1. Changes
    - Add `piece_id` column to `stripe_orders` table
    - Add foreign key constraint to link orders to specific pieces
    - Add index for better query performance
    - Update RLS policies to include piece-specific access

  2. Security
    - Maintain existing RLS policies
    - Ensure orders are linked to valid pieces
*/

-- Add piece_id column to stripe_orders table
ALTER TABLE stripe_orders 
ADD COLUMN IF NOT EXISTS piece_id uuid REFERENCES pieces(id) ON DELETE SET NULL;

-- Add index for better performance when querying orders by piece
CREATE INDEX IF NOT EXISTS stripe_orders_piece_id_idx ON stripe_orders(piece_id);

-- Add composite index for efficient user + piece donation checks
CREATE INDEX IF NOT EXISTS stripe_orders_customer_piece_idx ON stripe_orders(customer_id, piece_id);

-- Update the existing RLS policy to be more specific about piece access
DROP POLICY IF EXISTS "Users can view their own order data" ON stripe_orders;

CREATE POLICY "Users can view their own order data"
    ON stripe_orders
    FOR SELECT
    TO authenticated
    USING (
        customer_id IN (
            SELECT customer_id
            FROM stripe_customers
            WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
        AND deleted_at IS NULL
    );

-- Update the stripe_user_orders view to include piece_id
DROP VIEW IF EXISTS stripe_user_orders;

CREATE VIEW stripe_user_orders WITH (security_invoker) AS
SELECT
    c.customer_id,
    o.id as order_id,
    o.checkout_session_id,
    o.payment_intent_id,
    o.piece_id,
    o.amount_subtotal,
    o.amount_total,
    o.currency,
    o.payment_status,
    o.status as order_status,
    o.created_at as order_date
FROM stripe_customers c
LEFT JOIN stripe_orders o ON c.customer_id = o.customer_id
WHERE c.user_id = auth.uid()
AND c.deleted_at IS NULL
AND o.deleted_at IS NULL;