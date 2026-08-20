importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyB0cjtiRN9JCkmcvoyym6Rad_9YxgVj4OU",
    appId: "1:60771248934:web:9b262c5dc6a7e669a82fe7",
    messagingSenderId: "60771248934",
    projectId: "transport-intelligent-ia",
    authDomain: "transport-intelligent-ia.firebaseapp.com",
    storageBucket: "transport-intelligent-ia.firebasestorage.app",
});

const messaging = firebase.messaging();

// Gestion des notifications en arrière-plan (onglet inactif / fermé)
messaging.onBackgroundMessage((payload) => {
    console.log("[SW] Message reçu en arrière-plan :", payload);

    const title = payload.notification?.title ?? "Transport Intelligent";
    const body = payload.notification?.body ?? "";
    const icon = payload.notification?.icon ?? "/icons/Icon-192.png";

    return self.registration.showNotification(title, {
        body: body,
        icon: icon,
        badge: "/icons/Icon-72.png",
        tag: "camtrans-notif",
        renotify: true,
        vibrate: [200, 100, 200],
        data: { url: payload.data?.url ?? "/" },
    });
});

// Clic sur la notification : ouvre / ramène l'onglet de l'app
self.addEventListener("notificationclick", (event) => {
    event.notification.close();
    const targetUrl = event.notification.data?.url ?? "/";
    event.waitUntil(
        clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
            for (const client of clientList) {
                if (client.url.includes(self.location.origin) && "focus" in client) {
                    return client.focus();
                }
            }
            if (clients.openWindow) {
                return clients.openWindow(targetUrl);
            }
        })
    );
});
