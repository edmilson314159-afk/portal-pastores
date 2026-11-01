/* Portal dos Pastores – recebe os avisos (push) mesmo com o portal fechado */
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", e => e.waitUntil(self.clients.claim()));

self.addEventListener("push", e => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (_) { d = { body: e.data && e.data.text() }; }
  e.waitUntil(self.registration.showNotification(d.title || "Portal dos Pastores", {
    body: d.body || "",
    icon: "icone-verde-192.png",
    badge: "icone-verde-192.png",
    tag: d.tag || undefined,
    data: { url: d.url || "./" }
  }));
});

self.addEventListener("notificationclick", e => {
  e.notification.close();
  const url = new URL((e.notification.data && e.notification.data.url) || "./", self.registration.scope).href;
  e.waitUntil(self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(janelas => {
    for (const j of janelas) {
      if ("focus" in j) { if ("navigate" in j) j.navigate(url); return j.focus(); }
    }
    return self.clients.openWindow(url);
  }));
});
