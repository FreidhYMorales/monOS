#!/usr/bin/env bash
# Vendor the yazi plugins used by the monOS yazi configuration into
# profile/airootfs/etc/skel/.config/yazi/plugins, at pinned commits, so the
# live/installed system never downloads plugins (no `ya pkg` at runtime).
#
# Usage: ./branding/tools/vendor-yazi-plugins.sh   (needs git and network)
#
# Each plugin is copied as `ya pkg` would install it (top-level *.lua,
# LICENSE*, README.md, non-image files of assets/) and the pins are recorded
# in plugins/monos-plugins.txt. Running it again with the same pins changes
# nothing. To update a plugin, change its commit below, run the script and
# test yazi (the plugin's "--- @since" line gives the minimum yazi version).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="$ROOT/profile/airootfs/etc/skel/.config/yazi/plugins"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/monos-yazi-plugins"

# name|GitHub repository|commit|directory inside the repository|license
PLUGINS=(
  "bypass|Rolv-Apneseth/bypass.yazi|4a0c70ec9122d884deb659ff620af0098314c136|.|MIT"
  "clipboard|XYenon/clipboard.yazi|b25ec9697df1855634dc98d225a436d9c6783cec|.|AGPL-3.0"
  "fg|DreamMaoMao/fg.yazi|b9fb819d2c407795d0e0678ef33f0dd0b2db8bb3|.|MIT"
  "full-border|yazi-rs/plugins|4dc7f1b6458c2578f4494f10d468c68c1082214f|full-border.yazi|MIT"
  "gvfs|boydaihungst/gvfs.yazi|a85d65961b0ce99b472dd6e83b99062be178450b|.|MIT"
  "lazygit|Lil-Dank/lazygit.yazi|e73fd74c2af3300368b33da1cfbab6a8649a41a8|.|MIT"
  "mediainfo|boydaihungst/mediainfo.yazi|d2dd310bfbc3a819acf1c9c9c32f402ab6774d3a|.|MIT"
  "mount|yazi-rs/plugins|4dc7f1b6458c2578f4494f10d468c68c1082214f|mount.yazi|MIT"
  "ouch|ndtoan96/ouch.yazi|cfe4f507ef7337c8ad4c90eef68ea91fc6694759|.|MIT"
  "piper|yazi-rs/plugins|4dc7f1b6458c2578f4494f10d468c68c1082214f|piper.yazi|MIT"
  "recycle-bin|uhs-robert/recycle-bin.yazi|fe48a02778574b59ea15e289895f896a4e7e14eb|.|MIT"
  "relative-motions|dedukun/relative-motions.yazi|a603d9ea924dfc0610bcf9d3129e7cba605d4501|.|MIT"
  "what-size|pirafrank/what-size.yazi|ec94d9a8496241d91dcfb2a864214871c326ddc5|.|MIT"
  "yatline|imsi32/yatline.yazi|c5d4b487d6277dd68ea9d3c6537641bf4ae9cf8e|.|MIT"
)

mkdir -p "$CACHE" "$DEST"
manifest="$(mktemp)"
trap 'rm -f "$manifest"; rm -rf "${tmp:-}"' EXIT

cat >"$manifest" <<'EOF'
# yazi plugins vendored by monOS (branding/tools/vendor-yazi-plugins.sh).
# Each directory is an unmodified copy of the plugin at the commit below
# (*.lua, LICENSE, README.md, assets without screenshots). Their licenses
# apply: see the LICENSE file in each directory.
#
# plugin            license   source (https://github.com/<repository>) @ commit
EOF

for entry in "${PLUGINS[@]}"; do
  IFS='|' read -r name repo commit subdir license <<<"$entry"
  clone="$CACHE/${repo//\//__}"
  if [[ ! -d $clone/.git ]]; then
    git clone --quiet "https://github.com/$repo" "$clone"
  fi
  if ! git -C "$clone" cat-file -e "$commit^{commit}" 2>/dev/null; then
    git -C "$clone" fetch --quiet origin
  fi

  tmp="$(mktemp -d)"
  git -C "$clone" archive "$commit" -- "$subdir" | tar -x -C "$tmp"
  src="$tmp/$subdir"
  [[ -f $src/main.lua ]] || { echo "error: $name: no main.lua at $repo@$commit" >&2; exit 1; }
  if ! compgen -G "$src/LICENSE*" >/dev/null; then
    echo "error: $name: no LICENSE file at $repo@$commit" >&2
    exit 1
  fi

  out="$DEST/$name.yazi"
  rm -rf "$out"
  mkdir -p "$out"
  find "$src" -maxdepth 1 -type f \( -name '*.lua' -o -name 'LICENSE*' -o -name 'README.md' \) \
    -exec cp -p -t "$out" {} +
  if [[ -d $src/assets ]]; then
    while IFS= read -r -d '' asset; do
      mkdir -p "$out/assets"
      cp -p "$asset" "$out/assets/"
    done < <(find "$src/assets" -maxdepth 1 -type f \
      ! -iname '*.png' ! -iname '*.jpg' ! -iname '*.jpeg' ! -iname '*.gif' ! -iname '*.webp' -print0)
  fi
  find "$out" -type f -exec chmod 0644 {} +
  rm -rf "$tmp"
  unset tmp

  label=$repo
  [[ $subdir == . ]] || label+=":$subdir"
  printf '%-17s %-9s %s @ %s\n' "$name" "$license" "$label" "$commit" >>"$manifest"
  echo ":: $name ($license) $repo@${commit:0:7}"
done

cp "$manifest" "$DEST/monos-plugins.txt"
chmod 0644 "$DEST/monos-plugins.txt"
echo ":: vendored ${#PLUGINS[@]} plugins into ${DEST#"$ROOT"/}"
