/*
 * Privacy-first service worker.
 * It intentionally does not cache application responses, patient records,
 * API calls, documents, authentication pages, or any protected health data.
 * Its only purpose is to provide a controlled installable application shell.
 */
const VERSION = 'openemr-clinic-shell-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key.startsWith('openemr-clinic-') && key !== VERSION).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', () => {
  // Network behavior is left untouched. No protected response is cached.
});
