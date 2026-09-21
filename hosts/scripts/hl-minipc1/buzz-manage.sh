#!/usr/bin/env bash
# Buzz stack management — mirrors upstream block/buzz deploy/compose/run.sh,
# adapted to the container-services deployment: systemd unit instead of raw
# compose up/down, staged compose.yml, agenix env instead of a local .env.
#
# Expects these to be exported by the Nix wrapper before this file's content runs:
#   BUZZ_ENV_FILE    - agenix path of the buzz env file
#   BUZZ_COMPOSE_BIN - store path of docker-compose
set -euo pipefail

# Fallbacks so the file also runs directly from the repo for debugging.
BUZZ_ENV_FILE="${BUZZ_ENV_FILE:-/run/agenix/buzz-env}"
BUZZ_COMPOSE_BIN="${BUZZ_COMPOSE_BIN:-docker-compose}"

STATE_DIR="/var/lib/container-services/buzz"
COMPOSE_FILE="$STATE_DIR/compose.yml"
UNIT="container-services-buzz.service"
UPDATE_UNIT="container-services-buzz-update.service"

compose() {
	if [ ! -f "$COMPOSE_FILE" ]; then
		echo "$COMPOSE_FILE is not staged yet; run 'buzz-manage start' once" >&2
		exit 1
	fi
	"$BUZZ_COMPOSE_BIN" -p buzz -f "$COMPOSE_FILE" "$@"
}

require_env() {
	if [ ! -f "$BUZZ_ENV_FILE" ]; then
		cat >&2 <<MSG
Missing buzz env file: $BUZZ_ENV_FILE
It is decrypted by agenix at boot; check agenix.service if it is absent.
MSG
		exit 1
	fi
	if grep -Eq '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=.*CHANGE_ME' "$BUZZ_ENV_FILE"; then
		cat >&2 <<'MSG'
buzz-env still contains CHANGE_ME placeholders.
Generate stable secrets first; these values must not rotate on restart.
MSG
		exit 1
	fi
}

backup_hint() {
	cat <<'MSG'
Back up these before upgrades and on a regular schedule:

- secrets/buzz-env.age (relay private key, DB/Redis/S3 secrets, HMAC secret)
- secrets/buzz-tls-key.age and configs/pki/buzz.app.internal.crt (lab CA TLS)
- Postgres data on tnas1:/mnt/SmallG/buzz/postgres (prefer pg_dump or a quiesced snapshot)
- MinIO/S3 data on tnas1:/mnt/SmallG/buzz/s3 (bucket: buzz-media)
- git objects on tnas1:/mnt/SmallG/buzz/git (BUZZ_GIT_REPO_PATH=/data/git)
- Redis data on tnas1:/mnt/SmallG/buzz/redis

Keep Postgres + object/git state snapshots from the same maintenance window.
MSG
}

case "${1:-help}" in
	start|up)
		require_env
		systemctl start "$UNIT"
		;;
	stop|down)
		systemctl stop "$UNIT"
		;;
	restart)
		require_env
		compose up -d --wait --force-recreate relay
		;;
	pull)
		require_env
		compose pull
		;;
	upgrade)
		require_env
		# Same pull + recreate path the auto-update timer uses.
		systemctl start "$UPDATE_UNIT"
		echo "pull output: journalctl -u $UPDATE_UNIT"
		backup_hint
		;;
	logs)
		shift || true
		compose logs -f "${@:-relay}"
		;;
	status|ps)
		systemctl --no-pager status "$UNIT" || true
		compose ps
		;;
	config)
		require_env
		compose config
		;;
	backup-hint)
		backup_hint
		;;
	add-member)
		compose exec relay /usr/local/bin/buzz-admin add-member --pubkey "${2:?Usage: buzz-manage add-member <npub-or-hex> [--role member|admin]}" "${@:3}"
		;;
	remove-member)
		compose exec relay /usr/local/bin/buzz-admin remove-member --pubkey "${2:?Usage: buzz-manage remove-member <npub-or-hex> [--role member|admin]}" "${@:3}"
		;;
	list-members)
		compose exec relay /usr/local/bin/buzz-admin list-members
		;;
	help|-h|--help)
		cat <<'MSG'
Usage: buzz-manage <command>

Commands:
  start         Start the stack (container-services-buzz.service)
  stop          Stop containers without deleting volumes
  restart       Recreate the relay after env/image changes
  pull          Pull configured images
  upgrade       Pull and restart via the update unit, then print backup reminders
  logs [svc]    Follow logs (default: relay)
  status        Show systemd unit and compose service status
  config        Render merged compose config
  backup-hint   Print the production backup checklist

  add-member <npub-or-hex> [--role member|admin]
                Add a relay member (default role: member)
  remove-member <npub-or-hex> [--role member|admin]
                Remove a relay member
  list-members  List all relay members

  Note: when adding multiple members in a loop, add `sleep 1` between
  invocations to avoid same-second timestamp collisions in the kind:13534
  roster event. Do not use parallel adds (e.g. xargs -P).

Run as root (or via sudo): the env file and docker socket are root-only.
MSG
		;;
	*)
		echo "Unknown command: $1" >&2
		echo "Run 'buzz-manage help'" >&2
		exit 1
		;;
esac
