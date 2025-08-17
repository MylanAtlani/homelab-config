#!/bin/bash

CERTS_DIR="./certs"
OUTPUT_FILE="./dynamic/certs.yml"

mkdir -p ./dynamic

echo "tls:" > "$OUTPUT_FILE"
echo "  certificates:" >> "$OUTPUT_FILE"

# Boucle sur tous les certificats PEM
for pem_cert in "$CERTS_DIR"/*.pem; do
  [ -e "$pem_cert" ] || continue  # skip si aucun fichier

  domain=$(basename "$pem_cert" | sed 's/\.pem$//')
  key_file="$CERTS_DIR/${domain}-key.pem"
  crt_file="$CERTS_DIR/${domain}.crt"
  key_dest="$CERTS_DIR/${domain}.key"

  # Si .crt n'existe pas encore, crée-le à partir du .pem
  if [[ ! -f "$crt_file" ]]; then
    echo "➕ Convertion: $pem_cert -> $crt_file"
    cp "$pem_cert" "$crt_file"
  fi

  # Si .key n’existe pas avec la bonne extension, renomme
  if [[ -f "$key_file" && ! -f "$key_dest" ]]; then
    echo "🔄 Renommage: $key_file -> $key_dest"
    cp "$key_file" "$key_dest"
  fi

  # Ajoute la paire au fichier certs.yml
  if [[ -f "$crt_file" && -f "$key_dest" ]]; then
    echo "    - certFile: \"/etc/traefik/certs/$(basename "$crt_file")\"" >> "$OUTPUT_FILE"
    echo "      keyFile: \"/etc/traefik/certs/$(basename "$key_dest")\"" >> "$OUTPUT_FILE"
  fi
done

# Ajout des options TLS
cat >> "$OUTPUT_FILE" <<EOF

  options:
    default:
      sniStrict: true
EOF

echo "✅ Fichier $OUTPUT_FILE mis à jour avec les certificats trouvés."
