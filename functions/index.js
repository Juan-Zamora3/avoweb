const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializa el Admin SDK
admin.initializeApp();

// Función que se ejecuta cuando se elimina un documento en 'trabajadores'
exports.deleteAuthUser = functions.firestore
    .document("trabajadores/{workerId}")
    .onDelete(async (snap, context) => {
      const workerId = context.params.workerId; // UID del trabajador

      try {
      // Elimina al usuario de Firebase Authentication
        await admin.auth().deleteUser(workerId);
        console.log(`Usuario con UID ${workerId} eliminado de Authentication.`);
      } catch (error) {
        console.error(`Error al eliminar usuario con UID ${workerId}:`, error);
      }
    });
