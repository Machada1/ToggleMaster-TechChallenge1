#!/usr/bin/env bash
set -euo pipefail

# Altere antes de executar.
REPO_URL="${REPO_URL:-https://github.com/Machada1/ToggleMaster-TechChallenge1}"
APP_DIR="/opt/togglemaster"
APP_USER="togglemaster"
ENV_FILE="/etc/togglemaster/app.env"

if [[ "$REPO_URL" == \<URL_DO_REPOSITORIO_GIT\> ]]; then
  echo "Defina REPO_URL antes de executar: REPO_URL=https://... sudo bash deploy/bootstrap-ec2.sh" >&2
  exit 1
fi

dnf install -y git python3 python3-pip nginx postgresql15
id "$APP_USER" &>/dev/null || useradd --system --home-dir "$APP_DIR" --shell /sbin/nologin "$APP_USER"
install -d -o "$APP_USER" -g "$APP_USER" "$APP_DIR"

if [[ -d "$APP_DIR/.git" ]]; then
  git -C "$APP_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$APP_DIR"
fi

python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --upgrade pip
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

install -d -m 755 /etc/togglemaster
if [[ ! -e "$ENV_FILE" ]]; then
  install -o root -g root -m 600 "$APP_DIR/deploy/app.env.example" "$ENV_FILE"
  echo "Edite $ENV_FILE com os dados do RDS antes de iniciar o serviço."
else
  chmod 600 "$ENV_FILE"
  chown root:root "$ENV_FILE"
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a
: "${DB_HOST:?DB_HOST não definido em $ENV_FILE}"
: "${DB_NAME:?DB_NAME não definido em $ENV_FILE}"
: "${DB_USER:?DB_USER não definido em $ENV_FILE}"
: "${DB_PASSWORD:?DB_PASSWORD não definido em $ENV_FILE}"

echo "Aguardando PostgreSQL em ${DB_HOST}:5432..."
until PGPASSWORD="$DB_PASSWORD" pg_isready -h "$DB_HOST" -p 5432 -U "$DB_USER" -d "$DB_NAME" -q; do
  sleep 2
done

cd "$APP_DIR"
FLASK_APP=app.py "$APP_DIR/venv/bin/flask" init-db

install -o root -g root -m 644 "$APP_DIR/deploy/togglemaster.service" /etc/systemd/system/togglemaster.service
install -o root -g root -m 644 "$APP_DIR/deploy/nginx-togglemaster.conf" /etc/nginx/conf.d/togglemaster.conf
systemctl daemon-reload
systemctl enable --now togglemaster
systemctl enable --now nginx
nginx -t
systemctl reload nginx

cat <<'EOF'

Bootstrap concluído. Valide com:
  sudo systemctl status togglemaster nginx
  sudo journalctl -u togglemaster -n 100 --no-pager
  curl http://127.0.0.1/health
  curl http://<IP_PUBLICO>/health
  psql -h <ENDPOINT_RDS> -U <DB_USER> -d togglemaster -W -c '\dt'

Se o arquivo ainda tiver placeholders, edite /etc/togglemaster/app.env e execute:
  sudo systemctl restart togglemaster
EOF
