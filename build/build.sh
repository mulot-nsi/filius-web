#!/bin/bash
# Reconstruit public/filius/filius.jar à partir des sources de Filius.
#
# Sources utilisées : le paquet Filius de Debian/Ubuntu (sources officielles + correctifs Debian),
# auxquelles on applique build/filius-web.patch (ouverture/enregistrement des fichiers
# dans le navigateur). Le code est compilé pour Java 11, la version la plus éprouvée de CheerpJ.
#
# Prérequis : JDK 11 ou plus récent (javac, jar), curl, tar, xz, zstd, patch, unzip.
# Usage : ./build/build.sh   (depuis la racine du dépôt)
set -euo pipefail

VERSION="2.13.0"
DEB_REV="1"
MIROIR="http://archive.ubuntu.com/ubuntu/pool/universe/f/filius"

RACINE="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC="$RACINE/public/filius"
TRAVAIL="$(mktemp -d)"
trap 'rm -rf "$TRAVAIL"' EXIT
cd "$TRAVAIL"

echo "1. Téléchargement de Filius $VERSION"
curl -fsSLO "$MIROIR/filius_${VERSION}+ds.orig.tar.xz"
curl -fsSLO "$MIROIR/filius_${VERSION}+ds-${DEB_REV}.debian.tar.xz"
curl -fsSLO "$MIROIR/filius_${VERSION}+ds-${DEB_REV}_all.deb"

echo "2. Application des correctifs Debian et du correctif web"
tar xf "filius_${VERSION}+ds.orig.tar.xz"
tar xf "filius_${VERSION}+ds-${DEB_REV}.debian.tar.xz"
cd "filius-${VERSION}+ds"
while read -r p; do
  [ -n "$p" ] && patch -s -p1 < "../debian/patches/$p"
done < ../debian/patches/series
patch -s -p1 < "$RACINE/build/filius-web.patch"

echo "3. Compilation (Java 11)"
CP="$(ls "$PUBLIC"/lib/*.jar | tr '\n' ':')"
find src/main/java -name '*.java' > ../sources.txt
mkdir -p ../classes
javac --release 11 -nowarn -encoding UTF-8 -cp "$CP" -d ../classes @../sources.txt

echo "4. Assemblage de filius.jar"
# Les images et traductions viennent du paquet .deb (déjà générées par Debian).
cd "$TRAVAIL"
mkdir deb jar
if command -v dpkg-deb >/dev/null; then
  dpkg-deb -x "filius_${VERSION}+ds-${DEB_REV}_all.deb" deb
else
  # data.tar.zst : nécessite zstd (brew install zstd / apt install zstd)
  ar x "filius_${VERSION}+ds-${DEB_REV}_all.deb"
  tar xf data.tar.* -C deb
fi
cd jar
unzip -q ../deb/usr/share/filius/filius.jar
find . -name '*.class' -delete
rm -rf -- META-INF Name ----
cp -r ../classes/. .
printf 'Manifest-Version: 1.0\nMain-Class: filius.Main\n' > ../MANIFEST.MF
jar cfm "$PUBLIC/filius.jar" ../MANIFEST.MF .

# Ressources lues comme fichiers par Filius (aide, configuration, modèles)
for d in hilfe img tmpl; do
  rm -rf "${PUBLIC:?}/$d"
  cp -r "../deb/usr/share/filius/$d" "$PUBLIC/"
done
for f in Desktop_de_DE.txt Desktop_en_GB.txt Desktop_fr_FR.txt filetypes.txt; do
  cp "../deb/usr/share/filius/config/$f" "$PUBLIC/config/"
done
# public/filius/config/filius.ini est conservé : c'est le réglage de la version web (français par défaut).

echo "Terminé : $PUBLIC/filius.jar"
