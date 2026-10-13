#!/usr/bin/env bash
# -------------------------------------------------------------------
# oci-launch.sh — Keep trying to create an Oracle Cloud instance until
# the region has capacity for it
# -------------------------------------------------------------------
# The Always Free ARM shape is usually "Out of host capacity". This
# script repeats the launch request until one goes through, then prints
# the instance id and its public address.
#
# Usage:
#   ./oci-launch.sh --subnet <ocid> --ssh-key <file.pub> [options]
#
# Options (each one also reads the environment variable in parentheses):
#   --subnet <ocid>       Subnet of the instance (OCI_SUBNET_ID)
#   --ssh-key <file>      Public key authorized on the instance (OCI_SSH_KEY_FILE)
#   --compartment <ocid>  Compartment (OCI_COMPARTMENT_ID); defaults to the
#                         tenancy of the OCI CLI profile
#   --name <name>         Display name and hostname (default: oracle)
#   --shape <shape>       Shape (default: VM.Standard.A1.Flex)
#   --ocpus <n>           OCPUs for Flex shapes (default: 4)
#   --memory <gb>         Memory for Flex shapes (default: 24)
#   --boot-gb <n>         Boot volume size (default: 50)
#   --image <ocid>        Image; defaults to the newest Canonical Ubuntu
#                         24.04 image available for the shape
#   --ad <name>           Availability domain; defaults to trying every
#                         one in the region, in turn
#   --interval <seconds>  Wait between attempts (default: 60)
#   --profile <name>      OCI CLI profile (default: DEFAULT)
#   --once                Make a single attempt and exit
#
# NOTIFY_CMD, when set, is run once the instance is created.
#
# Examples:
#   ./oci-launch.sh --subnet ocid1.subnet.oc1... --ssh-key ~/.ssh/sol.pub
#   tmux new -s oci './oci-launch.sh --subnet ... --ssh-key ...'
# -------------------------------------------------------------------
set -euo pipefail

SUBNET="${OCI_SUBNET_ID:-}"
SSH_KEY="${OCI_SSH_KEY_FILE:-}"
COMPARTMENT="${OCI_COMPARTMENT_ID:-}"
NAME="oracle"
SHAPE="VM.Standard.A1.Flex"
OCPUS=4
MEMORY=24
BOOT_GB=50
IMAGE=""
AD=""
INTERVAL=60
PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"
ONCE=false

need_value() {
  [[ $# -ge 2 && -n "$2" ]] || {
    echo "❌ $1 needs a value."
    exit 1
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subnet) need_value "$@"; SUBNET="$2"; shift 2 ;;
    --ssh-key) need_value "$@"; SSH_KEY="$2"; shift 2 ;;
    --compartment) need_value "$@"; COMPARTMENT="$2"; shift 2 ;;
    --name) need_value "$@"; NAME="$2"; shift 2 ;;
    --shape) need_value "$@"; SHAPE="$2"; shift 2 ;;
    --ocpus) need_value "$@"; OCPUS="$2"; shift 2 ;;
    --memory) need_value "$@"; MEMORY="$2"; shift 2 ;;
    --boot-gb) need_value "$@"; BOOT_GB="$2"; shift 2 ;;
    --image) need_value "$@"; IMAGE="$2"; shift 2 ;;
    --ad) need_value "$@"; AD="$2"; shift 2 ;;
    --interval) need_value "$@"; INTERVAL="$2"; shift 2 ;;
    --profile) need_value "$@"; PROFILE="$2"; shift 2 ;;
    --once) ONCE=true; shift ;;
    -h | --help)
      sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "❌ Unknown option '$1'. See --help."
      exit 1
      ;;
  esac
done

# --- Preflight ---
command -v oci >/dev/null 2>&1 || {
  echo "❌ The 'oci' CLI is not installed (it comes from modules/shared/cli-dev.nix; run 'just switch')."
  exit 1
}
OCI_CONFIG="${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"
[[ -f "$OCI_CONFIG" ]] || {
  echo "❌ No OCI config at $OCI_CONFIG. Create an API key in the console and save the snippet it gives you there."
  exit 1
}
[[ -n "$SUBNET" ]] || {
  echo "❌ Missing --subnet (or OCI_SUBNET_ID)."
  exit 1
}
[[ "$SUBNET" == ocid1.subnet.* ]] || {
  echo "❌ '$SUBNET' is not a subnet OCID (it must start with ocid1.subnet.)."
  echo "   List the subnets of a VCN with: oci network subnet list --compartment-id <ocid> --vcn-id <vcn-ocid>"
  exit 1
}
[[ -n "$SSH_KEY" && -f "$SSH_KEY" ]] || {
  echo "❌ Missing --ssh-key (or OCI_SSH_KEY_FILE), or the file does not exist."
  exit 1
}

oci_cmd() {
  oci --profile "$PROFILE" --config-file "$OCI_CONFIG" "$@"
}

if [[ -z "$COMPARTMENT" ]]; then
  # Root compartment: the tenancy of the selected profile
  COMPARTMENT="$(awk -v section="[$PROFILE]" '
    $0 == section { found = 1; next }
    /^\[/ { found = 0 }
    found && /^tenancy[ \t]*=/ { sub(/^[^=]*=[ \t]*/, ""); print; exit }
  ' "$OCI_CONFIG")"
  [[ -n "$COMPARTMENT" ]] || {
    echo "❌ Could not read the tenancy of profile '$PROFILE' from $OCI_CONFIG. Pass --compartment."
    exit 1
  }
fi

if [[ -z "$IMAGE" ]]; then
  echo "🔎 Looking up the newest Canonical Ubuntu 24.04 image for $SHAPE..."
  IMAGE="$(oci_cmd compute image list \
    --compartment-id "$COMPARTMENT" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "24.04" \
    --shape "$SHAPE" \
    --sort-by TIMECREATED --sort-order DESC --limit 1 \
    --query 'data[0].id' --raw-output 2>/dev/null)"
  [[ "$IMAGE" == ocid1.image.* ]] || {
    echo "❌ No image found for $SHAPE. Pass --image."
    exit 1
  }
fi

if [[ -n "$AD" ]]; then
  ADS=("$AD")
else
  read -r -a ADS <<<"$(oci_cmd iam availability-domain list \
    --compartment-id "$COMPARTMENT" \
    --query "join(' ', data[].name)" --raw-output)"
  [[ ${#ADS[@]} -gt 0 ]] || {
    echo "❌ Could not list the availability domains."
    exit 1
  }
fi

LAUNCH_ARGS=(
  --compartment-id "$COMPARTMENT"
  --shape "$SHAPE"
  --subnet-id "$SUBNET"
  --image-id "$IMAGE"
  --assign-public-ip true
  --boot-volume-size-in-gbs "$BOOT_GB"
  --display-name "$NAME"
  --hostname-label "$NAME"
  --ssh-authorized-keys-file "$SSH_KEY"
)
if [[ "$SHAPE" == *.Flex ]]; then
  LAUNCH_ARGS+=(--shape-config "{\"ocpus\": $OCPUS, \"memoryInGBs\": $MEMORY}")
fi

echo "🚀 Trying to create '$NAME' ($SHAPE) in: ${ADS[*]}"
echo "   Image: $IMAGE"
echo "   One attempt per availability domain every ${INTERVAL}s. Ctrl-C to stop."

# --- Retry loop ---
ATTEMPT=0
INSTANCE_ID=""
while [[ -z "$INSTANCE_ID" ]]; do
  WAIT="$INTERVAL"
  for CURRENT_AD in "${ADS[@]}"; do
    ATTEMPT=$((ATTEMPT + 1))
    if OUTPUT="$(oci_cmd compute instance launch \
      --availability-domain "$CURRENT_AD" "${LAUNCH_ARGS[@]}" \
      --query 'data.id' --raw-output 2>&1)"; then
      INSTANCE_ID="$(grep -o 'ocid1\.instance\.[A-Za-z0-9._-]*' <<<"$OUTPUT" | head -n 1)"
      [[ -n "$INSTANCE_ID" ]] || {
        echo "❌ The launch succeeded but no instance id came back:"
        echo "$OUTPUT"
        exit 1
      }
      break
    fi

    MESSAGE="$(sed -n 's/.*"message": "\(.*\)".*/\1/p' <<<"$OUTPUT" | head -n 1)"
    MESSAGE="${MESSAGE:-$(tail -n 1 <<<"$OUTPUT")}"
    STAMP="$(date '+%Y-%m-%d %H:%M:%S')"

    if grep -qi 'out of.*capacity' <<<"$OUTPUT"; then
      echo "   [$STAMP] #$ATTEMPT $CURRENT_AD: no capacity"
    elif grep -q -e 'TooManyRequests' -e '"status": 429' <<<"$OUTPUT"; then
      # Back off: hammering the API only extends the throttling
      WAIT=$((INTERVAL * 5))
      echo "   [$STAMP] #$ATTEMPT $CURRENT_AD: throttled, waiting ${WAIT}s"
    elif grep -q 'LimitExceeded' <<<"$OUTPUT"; then
      echo "❌ Service limit reached: $MESSAGE"
      echo "   The Always Free allowance is probably in use already; check the instances in the console."
      exit 1
    elif grep -qi -e 'timed out' -e 'timeout' -e 'connection' -e '"status": 50[0-9]' <<<"$OUTPUT"; then
      echo "   [$STAMP] #$ATTEMPT $CURRENT_AD: temporary error ($MESSAGE)"
    else
      # Anything else (bad OCID, auth, permissions) will not fix itself
      echo "❌ Launch refused: $MESSAGE"
      echo "$OUTPUT"
      exit 1
    fi
  done

  [[ -n "$INSTANCE_ID" ]] && break
  if [[ "$ONCE" == true ]]; then
    echo "⏹️  No capacity on this attempt (--once)."
    exit 2
  fi
  # A little jitter so the requests do not land on a fixed beat
  sleep $((WAIT + RANDOM % 15))
done

echo ""
echo "✅ Instance created after $ATTEMPT attempt(s): $INSTANCE_ID"

# --- Public address ---
PUBLIC_IP=""
for _ in $(seq 1 30); do
  PUBLIC_IP="$(oci_cmd compute instance list-vnics --instance-id "$INSTANCE_ID" \
    --query 'data[0]."public-ip"' --raw-output 2>/dev/null || true)"
  [[ "$PUBLIC_IP" =~ ^[0-9.]+$ ]] && break
  PUBLIC_IP=""
  sleep 10
done

if [[ -n "$PUBLIC_IP" ]]; then
  echo "🌐 Public address: $PUBLIC_IP"
else
  echo "⚠️  The instance exists but has no public address yet; check the console."
fi

if [[ -n "${NOTIFY_CMD:-}" ]]; then
  INSTANCE_ID="$INSTANCE_ID" PUBLIC_IP="$PUBLIC_IP" bash -c "$NOTIFY_CMD" || true
fi

echo "🎉 Done. Next: add the host to configs/ssh/config and to the flake."
