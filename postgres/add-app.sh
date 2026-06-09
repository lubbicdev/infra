#!/bin/bash
set -e

APP_NAME="${1}"
APP_USER="${2:-${1}_user}"

# ────────────────────────────────────────────────────────────
# Validação
# ────────────────────────────────────────────────────────────
if [ -z "$APP_NAME" ]; then
  echo "Uso: $0 <nome_app> [usuario]"
  echo ""
  echo "Exemplos:"
  echo "  $0 meuapp"
  echo "  $0 meuapp meuapp_user"
  exit 1
fi

if ! echo "$APP_NAME" | grep -qE '^[a-z][a-z0-9_]*$'; then
  echo "❌ Nome inválido. Use apenas letras minúsculas, números e underscores."
  exit 1
fi

if [ ! -f ".env" ]; then
  echo "❌ .env não encontrado. Execute este script dentro da pasta postgres/."
  exit 1
fi

APP_DB="${APP_NAME}_db"
ENV_KEY="$(echo "${APP_NAME}" | tr '[:lower:]' '[:upper:]')_PASSWORD"

if grep -q "^${ENV_KEY}=" .env 2>/dev/null; then
  echo "❌ Aplicação '${APP_NAME}' já existe no .env (${ENV_KEY} já definido)."
  exit 1
fi

# ────────────────────────────────────────────────────────────
# Gerar senha segura
# ────────────────────────────────────────────────────────────
PASSWORD=$(openssl rand -hex 32)

echo "⚙️  Configurando: ${APP_NAME}"
echo "   Banco:   ${APP_DB}"
echo "   Usuário: ${APP_USER}"
echo "   Env var: ${ENV_KEY}"
echo ""

# ────────────────────────────────────────────────────────────
# 1. Atualizar .env
# ────────────────────────────────────────────────────────────
printf "\n# %s Application\n%s=%s\n" "$APP_NAME" "$ENV_KEY" "$PASSWORD" >> .env
echo "✅ .env atualizado"

# ────────────────────────────────────────────────────────────
# 2. Atualizar docker-compose.yml
# ────────────────────────────────────────────────────────────
ENV_LINE="      - ${ENV_KEY}=\${${ENV_KEY}}"
awk -v line="$ENV_LINE" '/^    volumes:/{print line}1' docker-compose.yml > docker-compose.tmp \
  && mv docker-compose.tmp docker-compose.yml
echo "✅ docker-compose.yml atualizado"

# ────────────────────────────────────────────────────────────
# 3. Atualizar postgres-init.sh
# ────────────────────────────────────────────────────────────
BLOCK_FILE=$(mktemp)

cat > "$BLOCK_FILE" << BLOCK_EOF

# ============================================================
# ${APP_NAME} Application
# ============================================================
psql -v ON_ERROR_STOP=1 --username "\$POSTGRES_USER" --dbname "\$POSTGRES_DB" \\
  -c "CREATE DATABASE ${APP_DB};" \\
  -c "CREATE USER ${APP_USER} WITH PASSWORD '\$${ENV_KEY}';" \\
  -c "GRANT ALL PRIVILEGES ON DATABASE ${APP_DB} TO ${APP_USER};"

psql -v ON_ERROR_STOP=1 --username "\$POSTGRES_USER" --dbname "${APP_DB}" \\
  -c "GRANT ALL ON SCHEMA public TO ${APP_USER};" \\
  -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${APP_USER};" \\
  -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${APP_USER};"

BLOCK_EOF

if grep -q "^# TEMPLATE" postgres-init.sh; then
  awk -v blockfile="$BLOCK_FILE" '
    /^# TEMPLATE/ {
      while ((getline line < blockfile) > 0) print line
      close(blockfile)
    }
    { print }
  ' postgres-init.sh > postgres-init.tmp && mv postgres-init.tmp postgres-init.sh
else
  cat "$BLOCK_FILE" >> postgres-init.sh
  echo "⚠️  Marcador não encontrado — bloco adicionado ao final do arquivo."
fi

rm -f "$BLOCK_FILE"
echo "✅ postgres-init.sh atualizado"

# ────────────────────────────────────────────────────────────
# 4. Aplicar no container se estiver rodando
# ────────────────────────────────────────────────────────────
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^postgres_server$"; then
  set -a
  # shellcheck disable=SC1091
  . .env
  set +a

  echo ""
  echo "🐳 Container rodando. Aplicando no banco diretamente..."

  docker exec postgres_server \
    env PGPASSWORD="$POSTGRES_PASSWORD" \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    -c "CREATE DATABASE ${APP_DB};" \
    -c "CREATE USER ${APP_USER} WITH PASSWORD '${PASSWORD}';" \
    -c "GRANT ALL PRIVILEGES ON DATABASE ${APP_DB} TO ${APP_USER};"

  docker exec postgres_server \
    env PGPASSWORD="$POSTGRES_PASSWORD" \
    psql -U "$POSTGRES_USER" -d "${APP_DB}" \
    -c "GRANT ALL ON SCHEMA public TO ${APP_USER};" \
    -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${APP_USER};" \
    -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${APP_USER};"

  echo "✅ Banco e usuário criados no container"
else
  echo "ℹ️  Container não está rodando — configurações ativas no próximo start."
fi

# ────────────────────────────────────────────────────────────
# Resumo
# ────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "🎉 Aplicação '${APP_NAME}' configurada com sucesso!"
echo "═══════════════════════════════════════════════════"
printf "   Banco:    %s\n" "$APP_DB"
printf "   Usuário:  %s\n" "$APP_USER"
printf "   Senha:    %s\n" "$PASSWORD"
printf "   Env var:  %s\n" "$ENV_KEY"
echo "═══════════════════════════════════════════════════"
echo "⚠️  Salve a senha acima — ela não será exibida novamente."
