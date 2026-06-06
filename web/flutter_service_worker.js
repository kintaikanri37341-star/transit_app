'use strict';

// ★ 即時更新モード（最重要）
self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

// ★ Flutter Web の標準キャッシュ設定
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

// Flutter が生成するリソース一覧（自動更新のために必要）
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
  // 必要に応じて追加（空でも動く）
};

// インストール処理
self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

// 有効化処理（古いキャッシュ削除）
self.addEventListener("activate", (event) => {
  event.waitUntil(async function () {
    try {
      const contentCache = await caches.open(CACHE_NAME);
      const tempCache = await caches.open(TEMP);

      await contentCache.addAll(await tempCache.keys());
      await caches.delete(TEMP);

      return;
    } catch (err) {
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
    }
  }());
});

// fetch 処理（キャッシュ優先）
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') return;

  const key = event.request.url.split(self.location.origin)[1] || "/";

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
