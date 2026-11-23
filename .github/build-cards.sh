#!/usr/bin/env bash
# Draws the stats card and the featured project cards in GitHub's own style,
# once for light mode and once for dark mode.
# To change which projects are featured, edit the `card` lines at the bottom.
set -euo pipefail
USER="${USER:?}"
mkdir -p cards

FONT="-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif"
STAR='M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.751.751 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25Zm0 2.445L6.615 5.5a.75.75 0 0 1-.564.41l-3.097.45 2.24 2.184a.75.75 0 0 1 .216.664l-.528 3.084 2.769-1.456a.75.75 0 0 1 .698 0l2.77 1.456-.53-3.084a.75.75 0 0 1 .216-.664l2.24-2.183-3.096-.45a.75.75 0 0 1-.564-.41L8 2.694Z'
DOWNLOAD='M2.75 14A1.75 1.75 0 0 1 1 12.25v-2.5a.75.75 0 0 1 1.5 0v2.5c0 .138.112.25.25.25h10.5a.25.25 0 0 0 .25-.25v-2.5a.75.75 0 0 1 1.5 0v2.5A1.75 1.75 0 0 1 13.25 14ZM7.25 7.689V2a.75.75 0 0 1 1.5 0v5.689l1.97-1.969a.749.749 0 1 1 1.06 1.06l-3.25 3.25a.749.749 0 0 1-1.06 0L4.22 6.78a.749.749 0 1 1 1.06-1.06l1.97 1.969Z'
REPO='M2 2.5A2.5 2.5 0 0 1 4.5 0h8.75a.75.75 0 0 1 .75.75v12.5a.75.75 0 0 1-.75.75h-2.5a.75.75 0 0 1 0-1.5h1.75v-2h-8a1 1 0 0 0-.714 1.7.75.75 0 1 1-1.072 1.05A2.495 2.495 0 0 1 2 11.5Zm10.5-1h-8a1 1 0 0 0-1 1v6.708A2.486 2.486 0 0 1 4.5 9h8ZM5 12.25a.25.25 0 0 1 .25-.25h3.5a.25.25 0 0 1 .25.25v3.25a.25.25 0 0 1-.4.2l-1.45-1.087a.249.249 0 0 0-.3 0L5.4 15.7a.25.25 0 0 1-.4-.2Z'

# GitHub's light and dark palettes: background, border, text, muted text, link
palette() {
  if [ "$1" = dark ]; then BG='#0d1117' BORDER='#3d444d' TEXT='#f0f6fc' MUTED='#9198a1' LINK='#4493f8'
  else BG='#ffffff' BORDER='#d1d9e0' TEXT='#1f2328' MUTED='#59636e' LINK='#0969da'; fi
}

fmt() { echo "$1" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'; }
sum() { awk '{s+=$1} END {print s+0}'; }
release_downloads() {
  gh api --paginate "repos/$USER/$1/releases?per_page=100" --jq '[.[].assets[].download_count] | add // 0' | sum
}

# ---- stats card ----
stars=$(gh api --paginate "users/$USER/repos?per_page=100" --jq '.[].stargazers_count' | sum)
commits=$(gh api "search/commits?q=author:$USER&per_page=1" --jq '.total_count')
downloads=0
for repo in $(gh api --paginate "users/$USER/repos?per_page=100" --jq '.[] | select(.fork|not) | .name'); do
  downloads=$(( downloads + $(release_downloads "$repo") ))
done

stat_cell() { # x label value
  echo "<text x=\"$(( $1 + 20 ))\" y=\"34\" font-size=\"12\" fill=\"$MUTED\">$2</text>"
  echo "<text x=\"$(( $1 + 20 ))\" y=\"66\" font-size=\"24\" font-weight=\"600\" fill=\"$TEXT\">$3</text>"
}

for mode in dark light; do
  palette $mode
  {
    echo "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"88\" viewBox=\"0 0 800 88\" font-family=\"$FONT\" role=\"img\" aria-label=\"$(fmt $stars) stars, $(fmt $commits) commits, $(fmt $downloads) release downloads\">"
    echo "<rect x=\"0.5\" y=\"0.5\" width=\"799\" height=\"87\" rx=\"6\" fill=\"$BG\" stroke=\"$BORDER\"/>"
    echo "<line x1=\"266.5\" y1=\"1\" x2=\"266.5\" y2=\"87\" stroke=\"$BORDER\"/>"
    echo "<line x1=\"533.5\" y1=\"1\" x2=\"533.5\" y2=\"87\" stroke=\"$BORDER\"/>"
    stat_cell 0 "Stars" "$(fmt $stars)"
    stat_cell 267 "Commits" "$(fmt $commits)"
    stat_cell 534 "Release downloads" "$(fmt $downloads)"
    echo "</svg>"
  } > "stats-$mode.svg"
done
echo "stats: $stars stars, $commits commits, $downloads downloads"

# ---- project cards ----
# card <repo> <title> <description line 1> <description line 2> <language label> <language colour> [label]
card() {
  local repo=$1 title=$2 d1=$3 d2=$4 lang=$5 color=$6 label=${7:-}
  local stars dl x
  stars=$(gh api "repos/$USER/$repo" --jq '.stargazers_count')
  dl=$(release_downloads "$repo")
  for mode in dark light; do
    palette $mode
    {
      echo "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"395\" height=\"128\" viewBox=\"0 0 395 128\" font-family=\"$FONT\" role=\"img\" aria-label=\"$title: $d1 $d2\">"
      echo "<rect x=\"0.5\" y=\"0.5\" width=\"394\" height=\"127\" rx=\"6\" fill=\"$BG\" stroke=\"$BORDER\"/>"
      echo "<svg x=\"16\" y=\"17\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\" fill=\"$MUTED\"><path d=\"$REPO\"/></svg>"
      echo "<text x=\"40\" y=\"30\" font-size=\"14\" font-weight=\"600\" fill=\"$LINK\">$title</text>"
      if [ -n "$label" ]; then
        local w=$(( ${#label} * 6 + 16 ))
        echo "<rect x=\"$(( 378 - w )).5\" y=\"16.5\" width=\"$w\" height=\"19\" rx=\"9.5\" fill=\"none\" stroke=\"$BORDER\"/>"
        echo "<text x=\"$(( 378 - w / 2 ))\" y=\"30\" font-size=\"11\" font-weight=\"500\" fill=\"$MUTED\" text-anchor=\"middle\">$label</text>"
      fi
      echo "<text x=\"16\" y=\"58\" font-size=\"12\" fill=\"$MUTED\">$d1</text>"
      echo "<text x=\"16\" y=\"76\" font-size=\"12\" fill=\"$MUTED\">$d2</text>"
      echo "<circle cx=\"22\" cy=\"104\" r=\"6\" fill=\"$color\"/>"
      echo "<text x=\"34\" y=\"108\" font-size=\"12\" fill=\"$MUTED\">$lang</text>"
      x=$(( 34 + ${#lang} * 7 + 16 ))
      echo "<svg x=\"$x\" y=\"97\" width=\"14\" height=\"14\" viewBox=\"0 0 16 16\" fill=\"$MUTED\"><path d=\"$STAR\"/></svg>"
      echo "<text x=\"$(( x + 18 ))\" y=\"108\" font-size=\"12\" fill=\"$MUTED\">$(fmt "$stars")</text>"
      if [ "$dl" -gt 0 ]; then
        x=$(( x + 18 + ${#stars} * 7 + 16 ))
        echo "<svg x=\"$x\" y=\"97\" width=\"14\" height=\"14\" viewBox=\"0 0 16 16\" fill=\"$MUTED\"><path d=\"$DOWNLOAD\"/></svg>"
        echo "<text x=\"$(( x + 18 ))\" y=\"108\" font-size=\"12\" fill=\"$MUTED\">$(fmt "$dl")</text>"
      fi
      echo "</svg>"
    } > "cards/$repo-$mode.svg"
  done
  echo "cards/$repo: $stars stars, $dl downloads"
}

card NSMBWiicompiled "NSMBWCompiled" \
  "Static recompilation of New Super Mario Bros. Wii." \
  "" \
  "C++" "#f34b7d"

card daydream "Daydream" \
  "Pogo platformer you control with your body:" \
  "lean to steer, scream to jump." \
  "GDScript" "#355570" "1st in votes"

card campfire "Campfire" \
  "3D boss fight controlled by webcam gestures:" \
  "raise a hand to attack, cross your arms to parry." \
  "C#" "#178600" "Best visuals"

card tunerapp "Sheet Music Tuner" \
  "Violin-first practice app that puts the tuner" \
  "right on your sheet music." \
  "TypeScript" "#3178c6"
