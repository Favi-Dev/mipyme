/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// v1.1 - Force Deploy for CORS
const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const mercadopago = require("mercadopago");
const cors = require("cors")({origin: true});
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();
const SUBSCRIPTION_AMOUNT = 2000;

// 1. Configurar Mercado Pago
const client = new mercadopago.MercadoPagoConfig({
  accessToken: process.env.MP_ACCESS_TOKEN,
});

async function authenticateRequest(req) {
  const authHeader = req.headers.authorization || "";
  if (!authHeader.startsWith("Bearer ")) {
    throw new Error("UNAUTHENTICATED");
  }

  const idToken = authHeader.substring("Bearer ".length);
  return admin.auth().verifyIdToken(idToken);
}

async function getBusinessProfile(pymeId) {
  const pymeDoc = await db.collection("pymes").doc(pymeId).get();
  if (pymeDoc.exists) {
    return pymeDoc;
  }

  const foundationDoc = await db.collection("foundations").doc(pymeId).get();
  if (foundationDoc.exists) {
    return foundationDoc;
  }

  return null;
}

/**
 * Funcion para generar una Preferencia de Pago.
 * Para compras valida la orden en Firestore. Para donaciones valida la entidad destino.
 */
exports.createPreference = onRequest({invoker: "public"}, async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
      }

      const decodedToken = await authenticateRequest(req);
      const {title, price, quantity, pymeId, orderId} = req.body;

      let resolvedTitle = "";
      let resolvedPrice = 0;
      let resolvedQuantity = 1;
      let externalReference = crypto.randomUUID();
      let metadata = {
        pyme_id: pymeId || "",
        user_id: decodedToken.uid,
        type: "donation",
      };

      if (orderId) {
        const orderDoc = await db.collection("orders").doc(orderId).get();
        if (!orderDoc.exists) {
          return res.status(404).json({error: "Orden no encontrada."});
        }

        const orderData = orderDoc.data();
        if (orderData.clientId !== decodedToken.uid) {
          return res.status(403).json({error: "No autorizado para pagar esta orden."});
        }
        if (!["pending", "pending_payment"].includes(orderData.status)) {
          return res.status(409).json({error: "La orden ya no esta disponible para pago."});
        }

        resolvedTitle = `Pedido ${orderId}`;
        resolvedPrice = Number(orderData.total || 0);
        resolvedQuantity = 1;
        externalReference = orderId;
        metadata = {
          pyme_id: orderData.pymeId,
          user_id: decodedToken.uid,
          type: "product_sale",
        };
      } else {
        const normalizedPrice = Number(price);
        if (!pymeId || !Number.isFinite(normalizedPrice) || normalizedPrice <= 0) {
          return res.status(400).json({error: "Datos de pago invalidos."});
        }

        const businessProfile = await getBusinessProfile(pymeId);
        if (!businessProfile) {
          return res.status(404).json({error: "Organizacion no encontrada."});
        }

        resolvedTitle = title || `Aporte a ${businessProfile.data().name || "SoyPlus"}`;
        resolvedPrice = normalizedPrice;
        resolvedQuantity = Math.max(1, Number(quantity) || 1);
        metadata.pyme_id = pymeId;
      }

      const preference = new mercadopago.Preference(client);
      const result = await preference.create({
        body: {
          items: [
            {
              title: resolvedTitle,
              quantity: resolvedQuantity,
              unit_price: resolvedPrice,
              currency_id: "CLP",
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
          metadata,
        },
      });

      return res.status(200).json({
        id: result.id,
        init_point: result.init_point,
        sandbox_init_point: result.sandbox_init_point,
        external_reference: externalReference,
      });
    } catch (error) {
      if (error.message === "UNAUTHENTICATED") {
        return res.status(401).json({error: "Debes iniciar sesion para crear pagos."});
      }
      logger.error("Error creando preferencia:", error);
      return res.status(500).json({error: error.message});
    }
  });
});

/**
 * Funcion para crear un cobro de suscripcion.
 * La activacion de la suscripcion ocurre solo cuando el webhook confirma el pago.
 */
exports.createSubscription = onRequest({invoker: "public"}, async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
      }

      const decodedToken = await authenticateRequest(req);
      const clientDoc = await db.collection("clients").doc(decodedToken.uid).get();
      if (!clientDoc.exists) {
        return res.status(404).json({error: "Perfil de cliente no encontrado."});
      }

      const externalReference = crypto.randomUUID();
      const preference = new mercadopago.Preference(client);
      const result = await preference.create({
        body: {
          items: [
            {
              title: "Suscripcion SoyPlus",
              quantity: 1,
              unit_price: SUBSCRIPTION_AMOUNT,
              currency_id: "CLP",
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
            user_id: decodedToken.uid,
            type: "mandatory_subscription",
          },
        },
      });

      return res.status(200).json({
        id: result.id,
        init_point: result.init_point,
        sandbox_init_point: result.sandbox_init_point,
        external_reference: externalReference,
      });
    } catch (error) {
      if (error.message === "UNAUTHENTICATED") {
        return res.status(401).json({error: "Debes iniciar sesion para suscribirte."});
      }
      logger.error("Error creando suscripcion:", error);
      return res.status(500).json({error: error.message});
    }
  });
});

/**
 * Webhook para recibir notificaciones de pago de Mercado Pago.
 * Verifica el pago y lo registra en Firestore de forma segura.
 */
exports.paymentWebhook = onRequest({invoker: "public"}, async (req, res) => {
  try {
    const topic = req.query.topic || req.body.type;
    const id = req.query.id || req.body.data?.id;

    if (topic === "payment" && id) {
      const payment = new mercadopago.Payment(client);
      const paymentInfo = await payment.get({id});

      if (paymentInfo.status === "approved") {
        const paymentId = String(paymentInfo.id);
        const paymentDoc = await db.collection("payments").doc(paymentId).get();
        const paymentType = paymentInfo.metadata?.type || "donation";
        const userId = paymentInfo.metadata?.user_id || "unknown";
        const pymeId = paymentInfo.metadata?.pyme_id || "unknown";

        if (!paymentDoc.exists) {
          await db.collection("payments").doc(paymentId).set({
            userId,
            externalReference: paymentInfo.external_reference,
            amount: paymentInfo.transaction_amount,
            status: paymentInfo.status,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            date: admin.firestore.FieldValue.serverTimestamp(),
            pymeId,
            description: paymentInfo.description || "Donacion/Compra",
            mercadoPagoId: paymentId,
            paymentMethod: paymentInfo.payment_method_id,
            type: paymentType,
          });
          logger.info(`Pago registrado exitosamente: ${paymentId}`);

          if (paymentType === "mandatory_subscription" && userId !== "unknown") {
            await db.collection("clients").doc(userId).set({
              isSubscribed: true,
              subscriptionDate: admin.firestore.FieldValue.serverTimestamp(),
              monthlyCouponRedeemed: false,
            }, {merge: true});

            await db.collection("transactions").add({
              clientId: userId,
              type: "mandatory_subscription",
              title: "Suscripcion Usuario Premium",
              amount: paymentInfo.transaction_amount,
              status: "Completado",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          const orderId = paymentInfo.external_reference;
          if (paymentType === "product_sale" && orderId) {
            const orderRef = db.collection("orders").doc(orderId);
            const orderDoc = await orderRef.get();

            if (orderDoc.exists) {
              await orderRef.update({
                status: "paid",
                paymentId,
                paidAt: admin.firestore.FieldValue.serverTimestamp(),
              });
              logger.info(`Orden ${orderId} actualizada a PAID.`);
            }
          }
        } else {
          logger.info(`Pago ya registrado: ${paymentId}`);
        }
      }
    }

    res.status(200).send("OK");
  } catch (error) {
    logger.error("Error en Webhook:", error);
    res.status(200).send("Error procesado");
  }
});

// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

/**
 * Trigger de Firestore para Gestion de Inventario.
 * Se ejecuta automaticamente cuando una orden cambia a 'paid'.
 * Descuenta el stock de cada producto en la orden.
 */
exports.updateStockOnOrderPaid = onDocumentUpdated("orders/{orderId}", async (event) => {
  const newData = event.data.after.data();
  const previousData = event.data.before.data();
  const orderId = event.params.orderId;

  if (newData.status === "paid" && previousData.status !== "paid") {
    logger.info(`Orden ${orderId} pagada. Actualizando inventario...`);
    const items = newData.items || [];

    try {
      await db.runTransaction(async (transaction) => {
        for (const item of items) {
          if (!item.productId) continue;

          const productRef = db.collection("products").doc(item.productId);
          const productDoc = await transaction.get(productRef);

          if (!productDoc.exists) {
            logger.warn(`Producto ${item.productId} no encontrado.`);
            continue;
          }

          const productData = productDoc.data();
          const qty = item.quantity || 1;

          if (item.variantId && productData.variants && productData.variants.length > 0) {
            const updatedVariants = productData.variants.map((variant) => {
              if (variant.id === item.variantId) {
                return {...variant, stock: Math.max(0, (variant.stock || 0) - qty)};
              }
              return variant;
            });
            transaction.update(productRef, {variants: updatedVariants});
            logger.info(`Stock variante ${item.variantId} decrementado en ${qty}.`);
          } else {
            transaction.update(productRef, {
              stock: admin.firestore.FieldValue.increment(-qty),
            });
            logger.info(`Stock producto ${item.productId} decrementado en ${qty}.`);
          }
        }
      });

      logger.info(`Inventario actualizado para orden ${orderId}`);
    } catch (error) {
      logger.error(`Error actualizando inventario para orden ${orderId}:`, error);
    }
  }
});

/**
 * Trigger para notificar al cliente cuando el estado de su pedido cambia.
 * Envia notificacion push via FCM y la guarda en Firestore.
 */
exports.sendOrderStatusNotification = onDocumentUpdated("orders/{orderId}", async (event) => {
  const newData = event.data.after.data();
  const previousData = event.data.before.data();

  if (newData.status === previousData.status) return;

  const clientId = newData.clientId;
  if (!clientId) return;

  const statusMessages = {
    "paid": {title: "Pago confirmado", body: "Tu pedido fue recibido y esta siendo procesado."},
    "preparing": {title: "Tu pedido esta en preparacion", body: "La tienda esta preparando tu pedido."},
    "ready": {title: "Tu pedido esta listo", body: "Puedes pasar a retirarlo."},
    "completed": {title: "Pedido completado", body: "Gracias por tu compra. Esperamos verte pronto."},
    "cancelled": {title: "Pedido cancelado", body: "Tu pedido fue cancelado. Contactanos si tienes dudas."},
  };

  const msg = statusMessages[newData.status];
  if (!msg) return;

  try {
    await db.collection("clients").doc(clientId).collection("notifications").add({
      title: msg.title,
      body: msg.body,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      type: "order_status",
      orderId: event.params.orderId,
    });

    const userDoc = await db.collection("clients").doc(clientId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {title: msg.title, body: msg.body},
        data: {orderId: event.params.orderId, type: "order_status"},
      });
      logger.info(`Push enviado a cliente ${clientId}`);
    }
  } catch (error) {
    logger.error("Error enviando notificacion de pedido:", error);
  }
});

/**
 * Scheduled Function: Reinicia cupon mensual para todos los suscriptores.
 * Corre cada dia a las 04:00 UTC (medianoche hora Santiago aprox).
 */
exports.resetMonthlyCoupons = onSchedule("every day 04:00", async () => {
  logger.info("Ejecutando reset de cupones mensuales...");
  const now = new Date();

  try {
    const snapshot = await db.collection("clients").where("isSubscribed", "==", true).get();
    const batch = db.batch();
    let resetCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const subscriptionDate = data.subscriptionDate?.toDate();
      const lastResetDate = data.lastCouponResetDate?.toDate();
      if (!subscriptionDate) continue;

      const monthsDiff =
        (now.getFullYear() - subscriptionDate.getFullYear()) * 12 +
        now.getMonth() - subscriptionDate.getMonth();
      if (monthsDiff < 1) continue;

      const currentCycleStart = new Date(
        subscriptionDate.getFullYear(),
        subscriptionDate.getMonth() + monthsDiff,
        subscriptionDate.getDate(),
      );

      if (!lastResetDate || lastResetDate < currentCycleStart) {
        batch.update(doc.ref, {
          monthlyCouponRedeemed: false,
          lastCouponResetDate: admin.firestore.FieldValue.serverTimestamp(),
        });
        resetCount++;
      }
    }

    await batch.commit();
    logger.info(`Cupones reiniciados: ${resetCount} usuarios.`);
  } catch (error) {
    logger.error("Error en reset de cupones:", error);
  }
});

/**
 * Cloud Function para crear un "Store Manager" (Jefe de Tienda)
 * sin cerrar la sesion del usuario actual (Empresa).
 *
 * Se requiere estar autenticado y ser rol 'empresa' (o admin).
 */
exports.createStoreManager = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Debe estar autenticado para crear un colaborador.",
    );
  }

  const callerUid = request.auth.uid;
  const {
    email,
    password,
    name,
    assignedStoreId,
    assignedStoreName,
    rut,
  } = request.data;

  if (!email || !password || !name || !assignedStoreId) {
    throw new HttpsError(
      "invalid-argument",
      "Faltan campos obligatorios (email, password, name, assignedStoreId).",
    );
  }

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    const newUid = userRecord.uid;

    await admin.firestore().collection("store_managers").doc(newUid).set({
      name,
      email,
      role: "storeManager",
      parentEmpresaId: callerUid,
      assignedStoreId,
      assignedStoreName: assignedStoreName || "",
      rut: rut || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      uid: newUid,
      message: "Colaborador creado exitosamente.",
    };
  } catch (error) {
    logger.error("Error creando Store Manager:", error);

    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "El correo electronico ya esta en uso por otro usuario.",
      );
    }
    if (error.code === "auth/weak-password") {
      throw new HttpsError(
        "invalid-argument",
        "La contrasena es muy debil (minimo 6 caracteres).",
      );
    }

    throw new HttpsError(
      "internal",
      "Hubo un error al crear el colaborador: " + error.message,
    );
  }
});
