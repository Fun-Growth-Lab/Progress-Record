// 研究進捗アプリ — Service Worker（最小構成）
// ネットワーク優先（常に最新）。オフライン時のみ直近のキャッシュで画面枠を開く。
// Supabase など別オリジンへの通信は一切さわらない。

const CACHE = 'rlab-v1';

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(clients.claim()));

self.addEventListener('fetch', e => {
    const req = e.request;
    if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
    e.respondWith(
        fetch(req).then(res => {
            const copy = res.clone();
            caches.open(CACHE).then(c => c.put(req, copy)).catch(() => {});
            return res;
        }).catch(() => caches.match(req))
    );
});
