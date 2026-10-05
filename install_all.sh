#!/usr/bin/env bash
set -uo pipefail

if [ $# -eq 0 ]; then
  read -p "Enter the GeoNature directory path: " GEONATURE_DIR
fi

GEONATURE_DIR="${1:-$GEONATURE_DIR}"
MONITORINGS_DST="$GEONATURE_DIR/backend/media/monitorings"
SRC_DIR="protocoles_suivi"

if [ -d "$SRC_DIR/.git" ]; then
  git -C "$SRC_DIR" pull --ff-only
else
  git clone git@github.com:PnX-SI/protocoles_suivi.git "$SRC_DIR"
fi

mkdir -p "$MONITORINGS_DST"
cp -r "$SRC_DIR"/* "$MONITORINGS_DST"

echo "CONTENU DU DOSSIER COPIÉ : $MONITORINGS_DST"
ls -al "$MONITORINGS_DST"

echo "Test install modules"
failed=()
for d in "$MONITORINGS_DST"/*/ ; do
  protocole="$(basename "$d")"

  # Ignorer ce qui n'est pas un protocole
  [ -f "$d/module.json" ] || { echo "⏭️  ${protocole} ignoré (pas de module.json)"; continue; }

  echo "➡️  install ${protocole}"
  log="install_${protocole}.log"

  if ! geonature monitorings install "$protocole" > "$log" 2>&1; then
    echo "❌ ${protocole} : commande en erreur (voir $log)"
    tail -n 50 "$log"
    failed+=("$protocole")
    continue
  fi

  if grep -Fq "Sous-module monitoring '${protocole}' installé" "$log"; then
    echo "✔️ ${protocole} OK : Module installé"
  else
    echo "❌ ${protocole} KO : Erreur à l'installation"
    tail -n 50 "$log"
    failed+=("$protocole")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "Échecs : ${failed[*]}"
  exit 1
fi
echo "Tous les protocoles sont installés"
