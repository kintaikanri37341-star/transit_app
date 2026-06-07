'use strict';

// ★ 即時更新（新しい SW をすぐ有効化）
self.addEventListener("install", (event) => {
  self.skipWaiting();
});

// ★ クライアントを即座に制御（ページリロード不要）
self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

// ★ Flutter Web の標準キャッシュ設定（最低限）
const CACHE_NAME = 'flutter-app-cache';
const TEMP = 'flutter-temp-cache';

// Flutter が必要とする最低限のリソース
const RESOURCES = {
  "index.html": "version",
  "/": "version",
  "main.dart.js": "version",
  "flutter.js": "version",
  "favicon.png": "version",
  "manifest.json": "version",
  "assets/AssetManifest.json": "version",
  "assets/FontManifest.json": "version",
  "assets/fonts/MaterialIcons-Regular.otf": "version",
};

// ★ インストール時：TEMP に必要ファイルを入れる
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

// ★ 有効化時：TEMP → 本番キャッシュへコピー
self.addEventListener("activate", (event) => {
  event.waitUntil(async function () {
    try {
      const contentCache = await caches.open(CACHE_NAME);
      const tempCache = await caches.open(TEMP);

      const tempRequests = await tempCache.keys();
      for (const request of tempRequests) {
        const response = await tempCache.match(request);
        if (response) {
          await contentCache.put(request, response.clone());
        }
      }

      await caches.delete(TEMP);
      return;
    } catch (err) {
      console.error('SW activation error:', err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
    }
  }());
});

// ★ 最重要：PWA 起動時にキャッシュを全削除（GitHub Pages 対策）
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.map((key) => caches.delete(key)))
    )
  );
});

// ★ fetch：キャッシュ優先（必要なら変更可能）
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') return;

  const origin = self.location.origin;
  let key = event.request.url.substring(origin.length);

  if (key === '' || key === '/') key = '/';
  if (!RESOURCES[key]) return;

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((response) => {
        return (
          response ||
          fetch(event.request).then((response) => {
            cache.put(event.request, response.clone());
            return response;
          })
        );
      });
    })
  );
});
