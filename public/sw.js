"use strict";

/* ------------------------------------------------------------------
   CheerpJ lit les fichiers de /app/ (les .jar, l'aide…) morceau par
   morceau, avec des requêtes HTTP « Range ». Le serveur Pages de la
   Forge ignore cet en-tête et renvoie toujours le fichier entier :
   CheerpJ refuse alors de démarrer.

   Ce service worker intercepte ces requêtes, télécharge une seule fois
   le fichier complet, puis répond lui-même avec le morceau demandé
   (réponse 206), comme le ferait un serveur qui gère « Range ».
   ------------------------------------------------------------------ */

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", e => e.waitUntil(self.clients.claim()));
// La page le demande quand elle n'est pas encore contrôlée (ex. Maj+Recharger).
self.addEventListener("message", e => {
  if (e.data === "prendre-le-controle") e.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", e => {
  const requete = e.request;
  const plage = requete.headers.get("range");
  if (!plage || requete.method !== "GET" || new URL(requete.url).origin !== self.location.origin) return;
  e.respondWith(repondreMorceau(requete.url, plage));
});

// Fichiers complets déjà téléchargés : adresse -> Promise<{ status, type, octets }>
const fichiers = new Map();

function fichierComplet(url) {
  if (!fichiers.has(url)) {
    const promesse = fetch(url).then(async reponse => ({
      status: reponse.status,
      type: reponse.headers.get("content-type") || "application/octet-stream",
      octets: reponse.ok ? await reponse.arrayBuffer() : null
    }));
    promesse.catch(() => fichiers.delete(url));
    fichiers.set(url, promesse);
  }
  return fichiers.get(url);
}

async function repondreMorceau(url, plage) {
  const fichier = await fichierComplet(url);
  if (!fichier.octets) return new Response(null, { status: fichier.status });

  const taille = fichier.octets.byteLength;
  const m = /^bytes=(\d*)-(\d*)$/.exec(plage.trim());
  let debut, fin;
  if (m && m[1] !== "") {
    debut = Number(m[1]);
    fin = m[2] !== "" ? Math.min(Number(m[2]), taille - 1) : taille - 1;
  } else if (m && m[2] !== "") {
    debut = Math.max(taille - Number(m[2]), 0);
    fin = taille - 1;
  }
  if (debut === undefined || debut >= taille || debut > fin) {
    return new Response(null, { status: 416, headers: { "Content-Range": "bytes */" + taille } });
  }

  return new Response(fichier.octets.slice(debut, fin + 1), {
    status: 206,
    headers: {
      "Content-Type": fichier.type,
      "Content-Range": "bytes " + debut + "-" + fin + "/" + taille,
      "Content-Length": String(fin - debut + 1),
      "Accept-Ranges": "bytes"
    }
  });
}
