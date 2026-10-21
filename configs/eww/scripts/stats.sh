#!/usr/bin/env bash
# CPU, GPU and RAM use as JSON. GPU: AMD iGPU busy %, plus the NVIDIA card
# while awake (see the comment in gpu() about querying it).
cpu() {
  local a b
  read -r _ a1 a2 a3 a4 a5 a6 a7 _ < /proc/stat
  sleep 0.5
  read -r _ b1 b2 b3 b4 b5 b6 b7 _ < /proc/stat
  a=$((a1 + a2 + a3 + a4 + a5 + a6 + a7)) b=$((b1 + b2 + b3 + b4 + b5 + b6 + b7))
  [ "$b" -eq "$a" ] && echo 0 && return
  echo $((100 * ((b - a) - (b4 - a4)) / (b - a)))
}

ram() {
  awk '/^MemTotal/ {t = $2} /^MemAvailable/ {a = $2} END {printf "%d", (t - a) * 100 / t}' /proc/meminfo
}

# The nitro5 (Ryzen 3000 + Turing) has no runtime D3: the NVIDIA card never
# sleeps, so querying it costs nothing. Where it can sleep, nvidia-smi would
# wake it, so then it is only flagged "NV".
gpu() {
  local igpu="" out dev rtd3 nv f
  for f in /sys/class/drm/card*/device/gpu_busy_percent; do
    [ -r "$f" ] && igpu="$(cat "$f")" && break
  done
  out="${igpu:-?}%"
  for dev in /sys/bus/pci/devices/*; do
    [ "$(cat "$dev/vendor" 2>/dev/null)" = "0x10de" ] || continue
    case "$(cat "$dev/class" 2>/dev/null)" in 0x0300* | 0x0302*) ;; *) continue ;; esac
    [ "$(cat "$dev/power/runtime_status" 2>/dev/null)" = "active" ] || continue
    rtd3="$(grep -s 'Runtime D3 status' "/proc/driver/nvidia/gpus/$(basename "$dev")/power")"
    if [[ "$rtd3" == *Enabled* ]] || ! command -v nvidia-smi >/dev/null; then
      out="$out · NV"
    else
      nv="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)"
      out="$out · NV ${nv:-?}%"
    fi
  done
  echo "$out"
}

jq -nc --arg cpu "$(cpu)%" --arg gpu "$(gpu)" --arg ram "$(ram)%" '{cpu: $cpu, gpu: $gpu, ram: $ram}'
