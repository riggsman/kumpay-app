/* Background handler for Firebase Cloud Messaging on the web.
   The pasted values live in /firebase-config.json. */
importScripts("https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js");

self.addEventListener("install", function () {
  self.skipWaiting();
});

fetch(new URL("/firebase-config.json", self.location.origin))
  .then(function (response) {
    return response.json();
  })
  .then(function (config) {
    if (!config.apiKey || !config.projectId || !config.appId || !config.messagingSenderId) {
      return;
    }
    firebase.initializeApp({
      apiKey: config.apiKey,
      authDomain: config.authDomain,
      projectId: config.projectId,
      storageBucket: config.storageBucket,
      messagingSenderId: config.messagingSenderId,
      appId: config.appId,
    });
    firebase.messaging();
  })
  .catch(function () {});
