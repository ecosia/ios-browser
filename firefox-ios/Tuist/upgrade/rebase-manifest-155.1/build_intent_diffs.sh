#!/bin/bash
# Generates the "Ecosia intent diff" manifest: for each Firefox-core file Ecosia
# modified, the exact diff of what Ecosia added on top of the firefox-v147.2
# base. This is the pre-merge ground truth of "what must survive" the rebase.
set -euo pipefail
cd /Users/jehmann/workspace/ios-browser

OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/intent-diffs"
mkdir -p "$OUT"
INDEX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/intent-diff-index.tsv"
echo -e "file\tecosia_markers\tadded_lines\tremoved_lines\tstatus" > "$INDEX"

while IFS= read -r f; do
  safe=$(echo "$f" | tr '/' '__')
  diff_file="$OUT/${safe}.diff"

  if ! git cat-file -e "firefox-v147.2:$f" 2>/dev/null; then
    echo -e "$f\tNA\tNA\tNA\tNO_BASELINE_AT_147.1" >> "$INDEX"
    continue
  fi

  git diff firefox-v147.2 HEAD -- "$f" > "$diff_file" 2>/dev/null || true

  markers=$(git show "HEAD:$f" 2>/dev/null | grep -c "// Ecosia:" || true)
  stat=$(git diff --numstat firefox-v147.2 HEAD -- "$f" 2>/dev/null)
  added=$(echo "$stat" | awk '{print $1}')
  removed=$(echo "$stat" | awk '{print $2}')
  added=${added:-0}
  removed=${removed:-0}

  status="OK"
  if [ ! -s "$diff_file" ]; then
    status="NO_ECOSIA_DIFF_FOUND"
  fi

  echo -e "$f\t$markers\t$added\t$removed\t$status" >> "$INDEX"
done < "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/core_modified_files.txt"

echo "Done. Index at $INDEX, diffs in $OUT"
wc -l "$INDEX"
