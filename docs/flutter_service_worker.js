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

// ★ fetch：キャッシュ優先
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


// ------------------------------------------------------------
// ★★★ アラーム機能（alarm.mp3 再生 + UI 自動解除対応） ★★★
// ------------------------------------------------------------

let alarmTimers = {}; // key: depart_timeHHmm → setTimeout ID

self.addEventListener('message', (event) => {
  if (!event.data) return;

  // ★ アラーム設定
  if (event.data.type === 'set-alarm') {
    const key = event.data.key; // "7:19" など
    const timestamp = event.data.timestamp;
    const delay = timestamp - Date.now();

    if (delay <= 0) return;

    // 既存アラームがあれば解除
    if (alarmTimers[key]) {
      clearTimeout(alarmTimers[key]);
    }

    alarmTimers[key] = setTimeout(() => {

      // ★ 通知表示
      self.registration.showNotification("バスの出発10分前です", {
        body: "そろそろ出発の準備をしてください。",
        icon: "/icons/Icon-192.png",
        vibrate: [200, 100, 200],
        requireInteraction: true,
        sound: "/alarm.mp3"
      });

      // ★ 裏技：音を直接鳴らす（Android Chrome で有効）
      try {
        const audio = new Audio("/alarm.mp3");
        audio.play();
      } catch (e) {
        console.log("音再生はブラウザにブロックされました");
      }

      // ★ Flutter へ「アラーム鳴った」通知を送る（UI 自動解除）
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({
            type: "alarm-fired",
            key: key
          });
        });
      });

      // ★ タイマー削除
      delete alarmTimers[key];

    }, delay);
  }

  // ★ アラーム解除
  if (event.data.type === 'cancel-alarm') {
    const key = event.data.key;

    if (alarmTimers[key]) {
      clearTimeout(alarmTimers[key]);
      delete alarmTimers[key];
    }
  }
});
