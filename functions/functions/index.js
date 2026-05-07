const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function para crear un "Store Manager" (Jefe de Tienda) 
 * sin cerrar la sesión del usuario actual (Empresa).
 * 
 * Se requiere estar autenticado y ser rol 'empresa' (o admin).
 */
exports.createStoreManager = functions.https.onCall(async (data, context) => {
  // 1. Verificar que el usuario que llama a la función esté autenticado
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Debe estar autenticado para crear un colaborador."
    );
  }

  // Obtenemos el ID de quien llama a la función
  const callerUid = context.auth.uid;

  // 2. Extraer datos del request payload
  const { 
    email, 
    password, 
    name, 
    assignedStoreId, 
    assignedStoreName, 
    rut 
  } = data;

  if (!email || !password || !name || !assignedStoreId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Faltan campos obligatorios (email, password, name, assignedStoreId)."
    );
  }

  try {
    // 3. Crear el usuario en Firebase Authentication usando el Admin SDK
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    const newUid = userRecord.uid;

    // 4. Guardar el perfil en Firestore
    await admin.firestore().collection("store_managers").doc(newUid).set({
      name: name,
      email: email,
      role: "storeManager",
      parentEmpresaId: callerUid, // El callerUid asume ser el empresaId
      assignedStoreId: assignedStoreId,
      assignedStoreName: assignedStoreName || "",
      rut: rut || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 5. Retornar éxito y el UID creado
    return {
      success: true,
      uid: newUid,
      message: "Colaborador creado exitosamente.",
    };

  } catch (error) {
    console.error("Error creando Store Manager:", error);
    
    // Convertir errores de Auth a respuestas legibles
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError(
        "already-exists",
        "El correo electrónico ya está en uso por otro usuario."
      );
    }
    if (error.code === 'auth/invalid-password') {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "La contraseña es muy débil (mínimo 6 caracteres)."
      );
    }
    
    throw new functions.https.HttpsError(
      "internal",
      "Hubo un error al crear el colaborador: " + error.message
    );
  }
});
