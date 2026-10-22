/* عامل الخدمة لتطبيق «حكايا رائد حجازي»
   - الصفحة الرئيسية: الشبكة أولاً، فيرى المستخدم آخر تحديث فوراً، ويُعرض المخزَّن عند انقطاع الاتصال.
   - الصور والأيقونات وملفات الموقع الأخرى: تُعرض من المخزَّن وتُحدَّث في الخلفية.
   - طلبات Supabase (المحتوى المضاف والتسجيلات والفيديوهات) لا تُخزَّن هنا، وتذهب إلى الشبكة كما هي.
   ارفع رقم الإصدار فقط إذا أردت مسح المخزَّن القديم لدى كل المستخدمين. */
const CACHE = "rh-cache-v1";
const CORE = ["./", "index.html", "manifest.webmanifest?v=4", "assets/icon-192.png?v=4", "assets/icon-512.png?v=4", "assets/favicon-64.png?v=4"];
const CDN = "https://cdn.jsdelivr.net/";

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).catch(() => {}).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k.startsWith("rh-cache-") && k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET" || req.headers.has("range")) return;
  const url = new URL(req.url);
  const sameOrigin = url.origin === self.location.origin;

  if (req.mode === "navigate" && sameOrigin) {
    e.respondWith(
      fetch(req).then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put("index.html", copy)); }
        return res;
      }).catch(() => caches.match("index.html").then(r => r || caches.match("./")))
    );
    return;
  }

  if (sameOrigin || req.url.startsWith(CDN)) {
    e.respondWith(caches.open(CACHE).then(c => c.match(req).then(hit => {
      const net = fetch(req).then(res => { if (res.ok) c.put(req, res.clone()); return res; }).catch(() => hit || Response.error());
      return hit || net;
    })));
  }
});
