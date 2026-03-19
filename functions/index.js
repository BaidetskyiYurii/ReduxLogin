const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
  const {token, title, body} = req.body;

  if (!token || !title || !body) {
    res.status(400).send("Missing token, title, or body in request");
    return;
  }

  const message = {
    notification: {
      title,
      body,
    },
    token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    res.status(200).send("Notification sent successfully");
  } catch (error) {
    console.error("Error sending message:", error);
    res.status(500).send("Failed to send notification");
  }
});
