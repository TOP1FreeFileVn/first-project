# Bot playtest metrics for levels 1-10: each level is played RUNS times with the profile a
# player plausibly has on reaching it (castle level, troop level, the team unlocked so far).
# Writes metrics.csv (level,run,phase,core_left,core_max,seconds). Run: bash metrics.sh
cd "$(dirname "$0")/../.."
G="C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe"
OUT="docs/bai-tap-giua-ki/metrics.csv"
RUNS=${RUNS:-4}
# level castle troop_level team
PROFILES="
1 1 1 pawn,warrior,archer
2 1 2 warrior,archer,lancer
3 2 3 warrior,archer,lancer,monk
4 2 4 warrior,archer,lancer,monk
5 3 5 warrior,archer,lancer,miner
6 3 6 warrior,lancer,guard,monk
7 4 7 warrior,lancer,guard,monk
8 4 8 lancer,guard,fire_archer,monk
9 5 9 lancer,guard,fire_archer,monk
10 5 10 lancer,guard,fire_archer,monk
"
echo "level,run,phase,core_left,core_max,seconds" > "$OUT"
play() {
  local level=$1 castle=$2 troops=$3 team=$4 run=$5
  local line
  line=$(timeout 600 "$G" --headless --fixed-fps 60 --path . res://tests/AutoPlay.tscn -- --level=$level --castle=$castle --troops=$troops --team=$team 2>/dev/null | grep RESULT)
  # RESULT level=1 phase=won core=115.0/115.0 time=89.6
  local phase core time
  phase=$(echo "$line" | sed -E 's/.*phase=([a-z]+).*/\1/')
  core=$(echo "$line" | sed -E 's/.*core=([0-9.]+)\/([0-9.]+).*/\1,\2/')
  time=$(echo "$line" | sed -E 's/.*time=([0-9.]+).*/\1/')
  echo "$level,$run,$phase,$core,$time"
}
echo "$PROFILES" | while read -r level castle troops team; do
  [ -z "$level" ] && continue
  for run in $(seq 1 "$RUNS"); do
    play "$level" "$castle" "$troops" "$team" "$run" >> "$OUT" &
  done
  wait
done
echo "done: $OUT"
