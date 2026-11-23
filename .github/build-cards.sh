#!/usr/bin/env bash
# Draws one card per featured project into cards/<repo>.svg.
# To change which projects are featured, edit the `card` lines at the bottom.
set -euo pipefail
USER="${USER:?}"
mkdir -p cards

fmt() { echo "$1" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'; }

# card <repo> <title> <description line 1> <description line 2> <language label> <colour> [award]
card() {
  local repo=$1 title=$2 d1=$3 d2=$4 lang=$5 color=$6 award=${7:-}
  local stars dl stats award_svg=""
  stars=$(gh api "repos/$USER/$repo" --jq '.stargazers_count')
  dl=$(gh api --paginate "repos/$USER/$repo/releases?per_page=100" \
        --jq '[.[].assets[].download_count] | add // 0' | awk '{s+=$1} END {print s+0}')
  stats="<tspan fill=\"#e3b341\">★</tspan> $(fmt "$stars")"
  if [ "$dl" -gt 0 ]; then
    stats="$stats<tspan dx=\"14\" fill=\"#00b7ff\">↓</tspan> $(fmt "$dl")"
  fi
  if [ -n "$award" ]; then
    local w=$(( ${#award} * 7 + 24 )) x
    x=$(( 368 - w ))
    award_svg="<rect x=\"$x\" y=\"21\" width=\"$w\" height=\"22\" rx=\"11\" fill=\"#e3b341\" fill-opacity=\"0.12\" stroke=\"#e3b341\" stroke-opacity=\"0.5\"/><text x=\"$(( x + w / 2 ))\" y=\"36\" class=\"award\" text-anchor=\"middle\">$award</text>"
  fi
  TITLE="$title" DESC1="$d1" DESC2="$d2" LANG="$lang" COLOR="$color" STATS="$stats" AWARD="$award_svg" \
    envsubst '$TITLE $DESC1 $DESC2 $LANG $COLOR $STATS $AWARD' < .github/project-template.svg > "cards/$repo.svg"
  echo "cards/$repo.svg: $stars stars, $dl downloads"
}

card NSMBWiicompiled "NSMBWCompiled" \
  "Static recompilation of New Super Mario Bros. Wii." \
  "" \
  "C++" "#f34b7d"

card daydream "Daydream" \
  "Pogo platformer you control with your body:" \
  "lean to steer, scream to jump. Made in one day." \
  "Godot · Python" "#478cbf" "1ST IN VOTES · 2ND OVERALL"

card campfire "Campfire" \
  "3D boss fight controlled by webcam gestures:" \
  "raise a hand to attack, cross your arms to parry." \
  "Unity · Python" "#b56bff" "BEST VISUALS"

card tunerapp "Sheet Music Tuner" \
  "Violin-first practice app that puts the tuner" \
  "right on your sheet music and trains your ear." \
  "TypeScript" "#3178c6"
