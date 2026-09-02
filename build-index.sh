#!/bin/sh
# Regenerates index.html — the page GitHub Pages serves — from realkredit-omlaegning.html.
#
# The source file is artifact-shaped: it starts at <title> with no <!doctype>, <html>,
# <head> or <body>, because the Artifact host injects those at publish time. Hosting it
# needs a real document, so this script wraps it: the source's <title>, font <link>s and
# <style> go into a proper <head>, the markup and script into <body>.
#
# The head below also restores the two rules the artifact skeleton normally provides and
# the page depends on: the viewport meta (without it the page loads zoomed out on a
# phone) and [hidden]{display:none!important} (the plain UA rule loses to .card-body's
# display:flex, so the yearly table would be open on load).
#
# Edit realkredit-omlaegning.html, never index.html, then run: ./build-index.sh
set -e
src=realkredit-omlaegning.html
out=index.html

{
  cat <<'HEAD'
<!doctype html>
<html lang="da">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Beregner: behold annuitetslånet eller læg om til et afdragsfrit lån — med udbetaling, investering, opsparing og rentefradrag.">
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.92em' font-size='92'>🏠</text></svg>">
<style>
  :root{color-scheme:light dark}
  body{margin:0}
  img{max-width:100%}
  [hidden]{display:none!important}
</style>
HEAD
  sed -n '1,/<\/style>/p' "$src"
  printf '</head>\n<body>\n'
  sed -n '/<\/style>/,$p' "$src" | tail -n +2
  printf '</body>\n</html>\n'
} > "$out"

echo "wrote $out ($(wc -c < "$out" | tr -d ' ') bytes)"
