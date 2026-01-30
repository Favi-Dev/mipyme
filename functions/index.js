/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// v1.1 - Force Deploy for CORS
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore"); // Importar Trigger Firestore
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const mercadopago = require("mercadopago");
const cors = require("cors")({origin: true});
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// 1. Configurar Mercado Pago
const client = new mercadopago.MercadoPagoConfig({ 
  accessToken: process.env.MP_ACCESS_TOKEN 
});

/**
 * Función para generar una Preferencia de Pago (Checkout Pro - Webpay/Invitado)
 * Esta función devuelve un link donde el usuario puede pagar.
 */
exports.createPreference = onRequest({ invoker: 'public' }, async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
      }

      const { title, price, quantity, pymeId, externalReference: providedRef } = req.body;
    // Si el cliente nos manda un ID de orden (externalReference), lo usamos. Si no, generamos uno nuevo.
    const externalReference = providedRef || crypto.randomUUID();

    const preference = new mercadopago.Preference(client);
    const result = await preference.create({
      body: {
        items: [
          {
            title: title,
            quantity: quantity || 1,
            unit_price: Number(price),
            currency_id: 'CLP',
          },
        ],
        back_urls: {
          success: "https://favi-dev.github.io/mipyme/",
          failure: "https://favi-dev.github.io/mipyme/",
          pending: "https://favi-dev.github.io/mipyme/",
        },
        auto_return: "approved",
        external_reference: externalReference,
        notification_url: "https://us-central1-soyplus-fec46.cloudfunctions.net/paymentWebhook",
        metadata: {
          pyme_id: pymeId
        }
      }
    });

      // Devolvemos el ID de la preferencia y el link de pago (init_point)
    return res.status(200).json({
      id: result.id,
      init_point: result.init_point,
      sandbox_init_point: result.sandbox_init_point, // Para pruebas
      external_reference: externalReference
    });

    } catch (error) {
      logger.error("Error creando preferencia:", error);
      return res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Función para crear un Preapproval (Suscripción Mensual Automática)
 * Requiere que el usuario ya tenga tarjeta inscrita (token) o seguir el flujo de inscripción.
 * Para MVP (Producto Mínimo Viable), usaremos el link de suscripción externo.
 */
exports.createSubscription = onRequest({ invoker: 'public' }, async (req, res) => {
  cors(req, res, async () => {
    try {
      const { title, price, payer_email } = req.body;
      
      const preapproval = new mercadopago.PreApproval(client);
      const result = await preapproval.create({
        body: {
            reason: title,
            auto_recurring: {
                frequency: 1,
                frequency_type: 'months',
                transaction_amount: Number(price),
                currency_id: 'CLP'
            },
            back_url: "https://favi-dev.github.io/mipyme/",
            payer_email: payer_email,
            status: "pending"
        }
      });

      return res.status(200).json({
        id: result.id,
        init_point: result.init_point, 
        sandbox_init_point: result.init_point // Preapproval usa el mismo link
      });

    } catch(error) {
       logger.error("Error creando suscripción:", error);
       return res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Webhook para recibir notificaciones de pago de Mercado Pago.
 * Verifica el pago y lo registra en Firestore de forma segura.
 */
exports.paymentWebhook = onRequest({ invoker: 'public' }, async (req, res) => {
  try {
    const { type, data } = req.body;
    // Soporte para ambos formatos de webhook (nuevo y legacy)
    const topic = req.query.topic || req.body.type; 
    const id = req.query.id || req.body.data?.id;

    if (topic === 'payment' && id) {
      const payment = new mercadopago.Payment(client);
      const paymentInfo = await payment.get({ id: id });
      
      if (paymentInfo.status === 'approved') {
         // Verificar si ya existe para no duplicar (Idempotencia)
         const paymentId = String(paymentInfo.id);
         const paymentDoc = await db.collection('payments').doc(paymentId).get();

         if (!paymentDoc.exists) {
            // 1. Guardar en colección 'payments' (Registro Auditoría)
            await db.collection('payments').doc(paymentId).set({
              userId: 'guest', // O sacar del metadata si lo enviamos
              externalReference: paymentInfo.external_reference,
              amount: paymentInfo.transaction_amount,
              status: paymentInfo.status,
              date: admin.firestore.FieldValue.serverTimestamp(),
              pymeId: paymentInfo.metadata.pyme_id || 'unknown',
              description: paymentInfo.description || 'Donación/Compra',
              mercadoPagoId: paymentId,
              paymentMethod: paymentInfo.payment_method_id,
              type: paymentInfo.metadata.type || 'donation' // 'donation' or 'order'
            });
            logger.info(`Pago registrado exitosamente: ${paymentId}`);

            // 2. Si es una COMPRA DE PRODUCTOS (Order), actualizamos el estado de la orden
            // El 'external_reference' DEBE ser el ID de la orden en Firestore
            const orderId = paymentInfo.external_reference;
            if (orderId && orderId.length > 5) { // Simple check to avoid UUIDs if we used them for donations
               const orderRef = db.collection('orders').doc(orderId);
               const orderDoc = await orderRef.get();
               
               if (orderDoc.exists) {
                  await orderRef.update({
                    status: 'paid', // Confirmamos la orden
                    paymentId: paymentId,
                    paidAt: admin.firestore.FieldValue.serverTimestamp()
                  });
                  logger.info(`Orden ${orderId} actualizada a PAID.`);
               }
            }

         } else {
            logger.info(`Pago ya registrado: ${paymentId}`);
         }
      }
    }
    
    // Siempre responder 200 a Mercado Pago para que deje de enviar la notificación
    res.status(200).send("OK");
  } catch (error) {
    logger.error("Error en Webhook:", error);
    // Responder 200 incluso con error interno para evitar reintentos infinitos de MP si es un bug nuestro
    res.status(200).send("Error procesado"); 
  }
});

// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started


/**
 * Trigger de Firestore para Gestión de Inventario.
 * Se ejecuta automáticamente cuando una orden cambia a 'paid'.
 * Descuenta el stock de cada producto en la orden.
 */
exports.updateStockOnOrderPaid = onDocumentUpdated("orders/{orderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const orderId = event.params.orderId;

    // Solo procedemos si el estado cambió a 'paid' y antes no lo estaba
    if (newData.status === 'paid' && previousData.status !== 'paid') {
        logger.info(`Orden ${orderId} pagada. Actualizando inventario...`);
        const items = newData.items || [];
        const batch = db.batch(); // Usamos Batch para atomicidad

        for (const item of items) {
            // item.productId, item.quantity
            if (item.productId) {
                const productRef = db.collection('products').doc(item.productId);
                // Decrementar stock usando atomic transaction logic (o decremento de campo)
                batch.update(productRef, {
                    stock: admin.firestore.FieldValue.increment(-item.quantity)
                });
            }
        }

        try {
            await batch.commit();
            logger.info(`Inventario actualizado para orden ${orderId}`);
        } catch (error) {
            logger.error(`Error actualizando inventario para orden ${orderId}:`, error);
        }
    }
});
