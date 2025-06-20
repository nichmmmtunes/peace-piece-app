import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import Stripe from 'npm:stripe@17.7.0';
import { createClient } from 'npm:@supabase/supabase-js@2.49.1';

const stripeSecret = Deno.env.get('STRIPE_SECRET_KEY')!;
const stripeWebhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')!;
const stripe = new Stripe(stripeSecret, {
  appInfo: {
    name: 'Bolt Integration',
    version: '1.0.0',
  },
});

const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

Deno.serve(async (req) => {
  try {
    // Handle OPTIONS request for CORS preflight
    if (req.method === 'OPTIONS') {
      return new Response(null, { status: 204 });
    }

    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    // get the signature from the header
    const signature = req.headers.get('stripe-signature');

    if (!signature) {
      return new Response('No signature found', { status: 400 });
    }

    // get the raw body
    const body = await req.text();

    // verify the webhook signature
    let event: Stripe.Event;

    try {
      event = await stripe.webhooks.constructEventAsync(body, signature, stripeWebhookSecret);
    } catch (error: any) {
      console.error(`Webhook signature verification failed: ${error.message}`);
      return new Response(`Webhook signature verification failed: ${error.message}`, { status: 400 });
    }

    EdgeRuntime.waitUntil(handleEvent(event));

    return Response.json({ received: true });
  } catch (error: any) {
    console.error('Error processing webhook:', error);
    return Response.json({ error: error.message }, { status: 500 });
  }
});

async function handleEvent(event: Stripe.Event) {
  const stripeData = event?.data?.object ?? {};

  if (!stripeData) {
    return;
  }

  if (!('customer' in stripeData)) {
    return;
  }

  // for one time payments, we only listen for the checkout.session.completed event
  if (event.type === 'payment_intent.succeeded' && event.data.object.invoice === null) {
    return;
  }

  const { customer: customerId } = stripeData;

  if (!customerId || typeof customerId !== 'string') {
    console.error(`No customer received on event: ${JSON.stringify(event)}`);
  } else {
    let isSubscription = true;

    if (event.type === 'checkout.session.completed') {
      const { mode } = stripeData as Stripe.Checkout.Session;

      isSubscription = mode === 'subscription';

      console.info(`Processing ${isSubscription ? 'subscription' : 'one-time payment'} checkout session`);
    }

    const { mode, payment_status } = stripeData as Stripe.Checkout.Session;

    if (isSubscription) {
      console.info(`Starting subscription sync for customer: ${customerId}`);
      await syncCustomerFromStripe(customerId);
    } else if (mode === 'payment' && payment_status === 'paid') {
      try {
        // Extract the necessary information from the session
        const {
          id: checkout_session_id,
          payment_intent,
          amount_subtotal,
          amount_total,
          currency,
          metadata,
        } = stripeData as Stripe.Checkout.Session;

        // Extract piece_id from metadata
        const piece_id = metadata?.piece_id || null;

        console.info(`Processing payment for piece: ${piece_id || 'unknown'}, amount: ${amount_total}`);

        // Insert the order into the stripe_orders table with piece_id
        const { error: orderError } = await supabase.from('stripe_orders').insert({
          checkout_session_id,
          payment_intent_id: payment_intent,
          customer_id: customerId,
          amount_subtotal,
          amount_total,
          currency,
          payment_status,
          status: 'completed', // assuming we want to mark it as completed since payment is successful
          piece_id: piece_id, // Store the piece_id from metadata
        });

        if (orderError) {
          console.error('Error inserting order:', orderError);
          return;
        }
        
        console.info(`Successfully processed one-time payment for session: ${checkout_session_id}, piece: ${piece_id || 'none'}`);

        // Update piece amount_raised if piece_id exists
        if (piece_id && amount_total) {
          try {
            const { error: pieceUpdateError } = await supabase
              .from('pieces')
              .update({
                amount_raised: supabase.sql`amount_raised + ${amount_total}`
              })
              .eq('id', piece_id);

            if (pieceUpdateError) {
              console.error('Error updating piece amount_raised:', pieceUpdateError);
            } else {
              console.info(`Updated piece ${piece_id} amount_raised by ${amount_total}`);
            }
          } catch (pieceError) {
            console.error('Error updating piece amount:', pieceError);
          }
        }

        // Update user total_donated_amount
        if (amount_total) {
          try {
            // Get the user_id from the customer
            const { data: customerData, error: customerError } = await supabase
              .from('stripe_customers')
              .select('user_id')
              .eq('customer_id', customerId)
              .single();

            if (customerError) {
              console.error('Error fetching customer data:', customerError);
            } else if (customerData?.user_id) {
              const { error: profileUpdateError } = await supabase
                .from('profiles')
                .update({
                  total_donated_amount: supabase.sql`total_donated_amount + ${amount_total}`
                })
                .eq('id', customerData.user_id);

              if (profileUpdateError) {
                console.error('Error updating user total_donated_amount:', profileUpdateError);
              } else {
                console.info(`Updated user ${customerData.user_id} total_donated_amount by ${amount_total}`);
              }
            }
          } catch (userError) {
            console.error('Error updating user donation amount:', userError);
          }
        }

        // If there's a piece_id, create a notification for the user
        if (piece_id) {
          try {
            // Get the user_id from the customer
            const { data: customerData } = await supabase
              .from('stripe_customers')
              .select('user_id')
              .eq('customer_id', customerId)
              .single();

            if (customerData?.user_id) {
              // Get piece title for the notification
              const { data: pieceData } = await supabase
                .from('pieces')
                .select('title')
                .eq('id', piece_id)
                .single();

              const pieceTitle = pieceData?.title || 'Peace Piece';

              // Create a notification for successful donation
              await supabase.from('notifications').insert({
                user_id: customerData.user_id,
                title: 'Thank you for your donation!',
                message: `Your donation to "${pieceTitle}" was successful. You now have access to view this piece and join the conversation.`,
                type: 'success',
                action_url: `/piece/${piece_id}`,
              });

              console.info(`Created notification for user ${customerData.user_id} for piece ${piece_id}`);
            }
          } catch (notificationError) {
            console.error('Error creating notification:', notificationError);
            // Don't fail the webhook for notification errors
          }
        }
      } catch (error) {
        console.error('Error processing one-time payment:', error);
      }
    }
  }
}

// based on the excellent https://github.com/t3dotgg/stripe-recommendations
async function syncCustomerFromStripe(customerId: string) {
  try {
    // fetch latest subscription data from Stripe
    const subscriptions = await stripe.subscriptions.list({
      customer: customerId,
      limit: 1,
      status: 'all',
      expand: ['data.default_payment_method'],
    });

    // TODO verify if needed
    if (subscriptions.data.length === 0) {
      console.info(`No active subscriptions found for customer: ${customerId}`);
      const { error: noSubError } = await supabase.from('stripe_subscriptions').upsert(
        {
          customer_id: customerId,
          subscription_status: 'not_started',
        },
        {
          onConflict: 'customer_id',
        },
      );

      if (noSubError) {
        console.error('Error updating subscription status:', noSubError);
        throw new Error('Failed to update subscription status in database');
      }
    }

    // assumes that a customer can only have a single subscription
    const subscription = subscriptions.data[0];

    // store subscription state
    const { error: subError } = await supabase.from('stripe_subscriptions').upsert(
      {
        customer_id: customerId,
        subscription_id: subscription.id,
        price_id: subscription.items.data[0].price.id,
        current_period_start: subscription.current_period_start,
        current_period_end: subscription.current_period_end,
        cancel_at_period_end: subscription.cancel_at_period_end,
        ...(subscription.default_payment_method && typeof subscription.default_payment_method !== 'string'
          ? {
              payment_method_brand: subscription.default_payment_method.card?.brand ?? null,
              payment_method_last4: subscription.default_payment_method.card?.last4 ?? null,
            }
          : {}),
        status: subscription.status,
      },
      {
        onConflict: 'customer_id',
      },
    );

    if (subError) {
      console.error('Error syncing subscription:', subError);
      throw new Error('Failed to sync subscription in database');
    }
    console.info(`Successfully synced subscription for customer: ${customerId}`);
  } catch (error) {
    console.error(`Failed to sync subscription for customer ${customerId}:`, error);
    throw error;
  }
}