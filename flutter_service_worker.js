'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "04464c1ee3df75572617f79284fbd2d4",
".git/config": "f8b3378d99fdbc264e393cffff907586",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/FETCH_HEAD": "308b251be1f45cf71c87ab199f927043",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "ed63d217ae7e5f508578ab94b7753b07",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "63566e0b5d3456dcf6a1d8942ae317bc",
".git/logs/refs/heads/main": "fa70a811bd2120cad24ecae7d17f2005",
".git/logs/refs/remotes/origin/main": "d3c0ae47cf0613e8a4193240c3f328ea",
".git/objects/04/1ca66bf44bc666885f926fcdff574890ab3466": "46c3452a7cdbec8ae7eac078c3b21b4a",
".git/objects/05/a9058f513cce5faf1704e06e3c150688b0a01f": "e8d02f60cf87abd4c1de4b153dd696dc",
".git/objects/06/5a156ad876ae75d08bca0aabc8c1e01f285abb": "1338ac20d12542d14345378e2fe2be26",
".git/objects/18/012585d7d0c8aeaba0747c73e3f4db9e634596": "47274c7c4d56ead80a60f2cd36525f72",
".git/objects/1a/91608f6b57e8ede858e1fcd9fbe7276e8d4195": "faca9e98446f8b377b9463dedaa912e3",
".git/objects/1e/1ac21e238f59b3aa63fd29fc046bf7140a2267": "7def3934e15e29f3bccd190583ce9274",
".git/objects/1f/45b5bcaac804825befd9117111e700e8fcb782": "7a9d811fd6ce7c7455466153561fb479",
".git/objects/27/a297abdda86a3cbc2d04f0036af1e62ae008c7": "51d74211c02d96c368704b99da4022d5",
".git/objects/2d/0471ef9f12c9641643e7de6ebf25c440812b41": "d92fd35a211d5e9c566342a07818e99e",
".git/objects/2d/1f66813fcc5aef477584b15c2b469783a96a49": "fd0a0e6bc120d4aee4a584c109763402",
".git/objects/35/ec3e4d11d30a2b7cdb2467c5c5107eba0677e1": "209c62fd30fc4a924a4c8c6e61a1bfc3",
".git/objects/36/0b63bcefcb7aa1b25859090aed63ed321e64ee": "1f31664b36da8439118a669ef235dfa1",
".git/objects/37/fa6b1039d9efa3d10694bc74af5b0962ab5649": "eceadf8c31f62b86c86ecfacfe760679",
".git/objects/39/a5bca847ee58fcd27ca8cfc7f53d0ffc0f69d6": "80f4f6ae2f90effad8d3cfd0f533e9fc",
".git/objects/3b/b0860a0981211a1ab11fced3e6dad7e9bc1834": "3f00fdcdb1bb283f5ce8fd548f00af7b",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/4d/5c537273ec41f5f3e309026d1176360438f9e8": "fe258f4dadc38deb55cb7c29feeeec2e",
".git/objects/4e/245f7c896f8e2afabaaab4b44973197a0e7cd5": "f5af2268b29a233b3cc92cda6b2c276c",
".git/objects/51/3dde20c20b946d94ba53e08e376f71ef78edc6": "685cf541528980edb0f3ba37d69ba578",
".git/objects/57/1895267e993f015a4a0720096731752b6a8444": "c5802aebd2c2871e1cc515a946652a0e",
".git/objects/5e/5a6fe1f84ace7683d891271c45184a88a7d0f6": "0894ae640e5e4f82fa531646e5db4a96",
".git/objects/62/c63a96b40f715a205f89006a7c42f5f9caec70": "48b0ce755f40d92fc75a3b0389d516a4",
".git/objects/63/6931bcaa0ab4c3ff63c22d54be8c048340177b": "8cc9c6021cbd64a862e0e47758619fb7",
".git/objects/65/99cf41a1416153cbba90abc2901516a8dded87": "382c4019b1ae897a594faed4307adb85",
".git/objects/68/dbc194d5e7c759807cc9ee7a28f8ad15d7e470": "42c6545510da430cf58bed70ed604ccb",
".git/objects/69/625c8cdca5dcd84d63751f5d1bad75c6accda1": "dcb088727de5bcdfe211afab42a011c5",
".git/objects/69/c08ef9efc74511afb31a91462aab7c38b58a8a": "78a8ff96d92cea7d468a6bad4bea0b99",
".git/objects/6d/1293d04173148fb807868eb7054d5bc5ee62b7": "88a05aefe4db2c47b5bc86b6f20494d3",
".git/objects/6d/5f0fdc7ccbdf7d01fc607eb818f81a0165627e": "2b2403c52cb620129b4bbc62f12abd57",
".git/objects/6e/c8e25dbb0a70a927d5125a6bf1b803166be5fd": "a7f23730ebb3656effa1351d56637cc9",
".git/objects/70/1f9ced6cea10a0a074ab5df79b915deca64d0f": "430b7c00c3abe1d9d5015cb1df0417a7",
".git/objects/73/7f149c855c9ccd61a5e24ce64783eaf921c709": "1d813736c393435d016c1bfc46a6a3a6",
".git/objects/76/9c264b490c0ffc67427f86dfe6e2506a31eece": "8935344b9be948f0b17e02545a07046b",
".git/objects/7b/e95115cb499103574c38f5c4d6a1a829f3fb4e": "a7d7ed9f9f6f7651d10722e3e5c66842",
".git/objects/7f/c560ec71f5421a3801aeda717ed161c90daf02": "cfbdf8e4731e83fcb51f11e62a9f6c3d",
".git/objects/81/80876b6824e864fc89cf1adff3b42909be07c2": "745b782c29e26c803fdbf35b7c032076",
".git/objects/85/6a39233232244ba2497a38bdd13b2f0db12c82": "eef4643a9711cce94f555ae60fecd388",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8c/59773bee8314a8ffb4431593d0fb49f52e34c6": "2eb993d30677573ffd0e58484cc6a514",
".git/objects/97/8a4d89de1d1e20408919ec3f54f9bba275d66f": "dbaa9c6711faa6123b43ef2573bc1457",
".git/objects/9b/39d97b2755f3a59938f0f8cdfd2f599500cb94": "7b1f778512bcdb17311f7c513415d9ad",
".git/objects/af/31ef4d98c006d9ada76f407195ad20570cc8e1": "a9d4d1360c77d67b4bb052383a3bdfd9",
".git/objects/b1/1dd5a7d83eb1ef1c1296aaadce14c22d4cd65b": "6cac42057d70ea1acea84820452fcdfd",
".git/objects/b1/5ad935a6a00c2433c7fadad53602c1d0324365": "8f96f41fe1f2721c9e97d75caa004410",
".git/objects/b1/afd5429fbe3cc7a88b89f454006eb7b018849a": "e4c2e016668208ba57348269fcb46d7b",
".git/objects/b3/a5e5cdb50b2f9132a699bbf8659c88938b54f4": "42d29c5a18eb610d4c2eb690201d932b",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/ba/5317db6066f0f7cfe94eec93dc654820ce848c": "9b7629bf1180798cf66df4142eb19a4e",
".git/objects/bc/7cc0ad75e59f5be904f6ab4e6c4c63a9671220": "4d85a3abb441b85281628cd778d7b1e0",
".git/objects/bd/07199e06ede3249a5a92540f0b0e118080d98d": "7ae1287843478845b3732bf026e9fe37",
".git/objects/c3/e81f822689e3b8c05262eec63e4769e0dea74c": "8c6432dca0ea3fdc0d215dcc05d00a66",
".git/objects/c6/06caa16378473a4bb9e8807b6f43e69acf30ad": "ed187e1b169337b5fbbce611844136c6",
".git/objects/c7/7663172ca915a99a594ca17d06f527db05657d": "6335b074b18eb4ebe51f3a2c609a6ecc",
".git/objects/ce/aa6381478b4158f1c917c4df6ffe374355ab74": "ce2479f67df51bc62dd58676d658780b",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d8/b7c0da9dc8b8a9717a6d5295488a5b8a63920d": "594a55c4b04b3f3c71fdf9257bd1ae46",
".git/objects/da/0abde1a72584c52596f0f81e2bafd666759b1d": "1029b3fb59ad5d7e2ac230f0bf771d8f",
".git/objects/df/cb1619172c6d0e010a37b4bb00449062a2e30c": "7e03366612410622957b58877c1fe85e",
".git/objects/e2/59ed4ee43e51f4966722c0f5607cb6394e18a4": "58f9e6907ab38ba20b4dcb47396fc722",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ec/361605e9e785c47c62dd46a67f9c352731226b": "d1eafaea77b21719d7c450bcf18236d6",
".git/objects/ed/90cb94d0dc0d1c7dcf3dbde9f31a80805b8f72": "5800ad084e5f7cea4c0b64ff40917f49",
".git/objects/f0/30f1f5d3430297eb7b1748b8a0ba3aeece9deb": "a30f3951d98bcf5b0a7c73ce9c2374cf",
".git/objects/f0/4b05e7dafc42dc4bc42b122c818296ed4885f7": "b2a40171ac6ab096be9f66975b77b020",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/fa/72ff3d15bc6a48220018a88612b361ac818b30": "6862c4b0b1d3a61cfebd45551dcccd6d",
".git/objects/fb/7e8a637fd3c721811f4c7969c63ec5377ecd6d": "78c14b350fded9bc307bcf869bf6579d",
".git/objects/fc/7959ab506f2efe0bb0b494e0f3c01f3a0b5962": "b717717fd571963ac27ebb2e76e78b75",
".git/objects/ff/147071ce4b33106dcae122ecf74d4bfc8ead64": "96b4efca103736574a1dc6ce4adf8627",
".git/ORIG_HEAD": "f2c090158be7eeffa9febb9c70fe3c80",
".git/refs/heads/main": "48b584296cdcafac00700180999d64e4",
".git/refs/remotes/origin/main": "48b584296cdcafac00700180999d64e4",
"assets/AssetManifest.bin": "0ff56ba7b2355c4b0afb7b66602f837b",
"assets/AssetManifest.bin.json": "1ce9100908ca8d82b9893f191c23655b",
"assets/AssetManifest.json": "0a773769fa974ce3af0bccb506dc065c",
"assets/assets/images/avatar.png": "5405d77c51fb46a0cbf26cb96fe4da4d",
"assets/assets/images/avocato_background.jpg": "1546d35b39647dca787da8d3cce2b516",
"assets/assets/images/avocato_logo.png": "2bde5a1d5a620f62c9827fd38003e04e",
"assets/assets/images/fondopantalla.png": "c46ed8ce472046e4ae40df3d3cdae772",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "34fe3d23a86a8e2d63878840544d9296",
"assets/NOTICES": "c52f03c060ac4ca2e6ab2c33d40e4455",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"flutter_bootstrap.js": "c3c4103bc1de9de453d964c427cabbe8",
"icons/favicon-16x16.png": "07d6b0a8ab3a46e27c5dde29bb20d851",
"icons/favicon-32x32.png": "9c6ac5d010bcfb3184d8e511e553aba4",
"icons/Icon-192.png": "0b94db07a623228856b201431e5e6f79",
"icons/Icon-512.png": "8165186e78a07cc8eecf99616439ddce",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "ef759cdda9645a5604f8b024e5e6de5e",
"/": "ef759cdda9645a5604f8b024e5e6de5e",
"main.dart.js": "ae06bedf7d43be2405ce98490adf4786",
"manifest.json": "eb0c1fff09c1b33dbd41c61f2d67238b",
"version.json": "c12bded33cd582cfd197536b84d45f73"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
