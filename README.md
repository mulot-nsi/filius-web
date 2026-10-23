# Filius en ligne

[Filius](https://www.lernsoftware-filius.de), le simulateur de réseaux, directement dans le navigateur. Les élèves n'ont rien à installer : ils ouvrent une page web et Filius démarre.

Le programme Java d'origine tourne dans le navigateur grâce à [CheerpJ](https://cheerpj.com), une machine virtuelle Java en WebAssembly. Tout s'exécute sur le poste de l'élève : le serveur ne fait que distribuer des fichiers statiques. Une page GitLab Pages suffit donc, quel que soit le nombre d'élèves.

## Publier sur la Forge

1. Sur [forge.apps.education.fr](https://forge.apps.education.fr), créez un projet vide, par exemple `filius-web`.
2. Envoyez le contenu de ce dossier dans le projet :

   ```bash
   cd filius-web
   git init -b main
   git add .
   git commit -m "Filius en ligne"
   git remote add origin https://forge.apps.education.fr/<votre-identifiant>/filius-web.git
   git push -u origin main
   ```

3. Le pipeline (fichier `.gitlab-ci.yml`) publie automatiquement le dossier `public/`. Suivez-le dans **Compilation › Pipelines**.
4. L'adresse du site apparaît dans **Déploiement › Pages**. Elle ressemble à `https://<votre-identifiant>.forge.apps.education.fr/filius-web/`. Si le projet est privé, réglez la visibilité de Pages sur « Tout le monde » dans **Paramètres › Général › Visibilité**.

Le site fonctionne à n'importe quelle adresse, dans n'importe quel sous-dossier : aucun chemin n'est à modifier. Seul le lien vers le projet, en bas de la page d'accueil, est à compléter : dans `public/index.html`, remplacez `https://forge.apps.education.fr/` dans la ligne `id="lien-forge"` (l’icône GitLab en bas de page) par l’adresse de votre projet.

## Tester sur son ordinateur

CheerpJ ne fonctionne pas en ouvrant `index.html` par un double-clic. Il faut passer par un petit serveur web :

```bash
cd public
python3 -m http.server 8000
```

Puis ouvrez <http://localhost:8000/>. Une connexion à Internet est nécessaire, car CheerpJ est chargé depuis `cjrtnc.leaningtech.com`.

## Utilisation

- **Lancer Filius** : un réseau vide, en français.
- **Ouvrir un fichier .fls** : depuis l'accueil, ou avec le bouton « Ouvrir » (dossier) de Filius. Une fenêtre du navigateur permet de choisir le fichier ou de le glisser.
- **Enregistrer** : le bouton disquette de Filius demande un nom de fichier, puis le navigateur télécharge le `.fls` dans le dossier Téléchargements.

## Partager un exercice

Un lien peut ouvrir Filius directement sur un réseau préparé. Ajoutez `?fichier=` suivi de l'adresse d'un fichier `.fls` à l'adresse du site :

```
https://<votre-identifiant>.forge.apps.education.fr/filius-web/?fichier=<adresse du fichier .fls>
```

Le fichier peut être publié à deux endroits :

- **Sur ce site.** Déposez-le dans `public/`, par exemple dans un dossier `public/exercices/`, puis indiquez son chemin relatif : `…/filius-web/?fichier=exercices/dns.fls`. Après le `git push`, le fichier est en ligne.
- **Ailleurs.** Indiquez l'adresse complète : `…/filius-web/?fichier=https://autre-site.fr/dns.fls`. Le serveur qui héberge le fichier doit autoriser son téléchargement depuis une autre page (en-tête CORS), ce qui n'est pas toujours le cas. En cas de doute, préférez la première solution.

Les élèves reçoivent chacun leur propre copie du réseau. Leurs modifications restent dans leur navigateur jusqu'à ce qu'ils les enregistrent avec la disquette.

## Contenu du dépôt

```
public/                  le site publié
  index.html             page d'accueil + lancement de Filius avec CheerpJ
  filius/filius.jar      Filius 2.13.0, compilé pour Java 11, avec le correctif web
  filius/lib/            bibliothèques utilisées par Filius (Batik, iText, Spring, Logback…)
  filius/config/         configuration ; filius.ini force le français
  filius/hilfe, img, tmpl  aide en ligne et modèles de Filius
  logo-filius.png        logo officiel de Filius (icône de l'application)
build/
  build.sh               reconstruit filius.jar à partir des sources officielles
  filius-web.patch       modifications apportées à Filius
.gitlab-ci.yml           publication sur GitLab Pages
```

## Modifications apportées à Filius

Filius est utilisé tel quel, à trois petites modifications près (fichier `build/filius-web.patch`). Elles ne s'activent que dans le navigateur, avec la propriété `filius.web=true` :

- **Ouvrir** et **Enregistrer** passent par le navigateur (sélecteur de fichier et téléchargement) au lieu de la boîte de dialogue Java, qui ne montrerait que le disque virtuel du navigateur.
- Les ressources (aide, configuration) sont lues depuis le dossier `public/filius/`, indiqué par la propriété `filius.resources`.
- La classe `filius.web.WebBridge` fait le lien avec la page : ses méthodes natives sont écrites en JavaScript dans `index.html`.

Pour passer à une nouvelle version de Filius, modifiez `VERSION` dans `build/build.sh`, puis lancez le script (il faut un JDK 11 ou plus récent).

## Limites connues

- Le premier lancement peut prendre jusqu'à une minute (téléchargement de Java dans le navigateur). Les suivants profitent du cache.
- Les préférences de Filius sont stockées dans le navigateur. Seuls les fichiers téléchargés sont de vraies sauvegardes : vider les données du navigateur ou utiliser une fenêtre privée efface le reste.
- L'assistant de création de logiciels de Filius est désactivé : il a besoin d'un compilateur Java, absent du navigateur.
- Prévu pour les navigateurs récents (Firefox, Chrome, Edge). Safari est pris en charge par CheerpJ, mais il est moins éprouvé.

## Licences

- **Filius** : logiciel libre sous licence GPL (voir `GPLv2.txt` et `GPLv3.txt`), © Stefan Freischlad et contributeurs. Les sources utilisées sont celles du paquet Debian/Ubuntu `filius` (`build/build.sh` les télécharge). Les modifications sont dans `build/filius-web.patch`.
- **Bibliothèques** de `public/filius/lib/` : elles proviennent des paquets Debian/Ubuntu correspondants (Apache Batik, Spring, Commons, Logback/SLF4J : licences Apache, EPL ou MIT ; iText 5 : AGPL). Leurs sources sont disponibles dans les archives Debian et Ubuntu.
- **CheerpJ** est chargé depuis les serveurs de Leaning Technologies sous [licence Community](https://cheerpj.com/licensing/), gratuite pour les logiciels libres comme Filius. Pour un déploiement à grande échelle (toute une académie, par exemple), mieux vaut contacter Leaning Technologies : l'éditeur propose des licences gratuites ou à prix réduit pour l'éducation.
