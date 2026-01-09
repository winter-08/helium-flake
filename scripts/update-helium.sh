#!/usr/bin/env bash
set -euo pipefail

linux_json="$(curl -sSL https://api.github.com/repos/imputnet/helium-linux/releases/latest)"
mac_json="$(curl -sSL https://api.github.com/repos/imputnet/helium-macos/releases/latest)"

version="$(jq -r .tag_name <<<"$linux_json")"
mac_version="$(jq -r .tag_name <<<"$mac_json")"
if [[ -z "$version" || "$version" == "null" ]]; then
  echo "error: missing linux tag_name" >&2
  exit 1
fi
if [[ "$version" != "$mac_version" ]]; then
  echo "error: version mismatch linux=$version mac=$mac_version" >&2
  exit 1
fi

digest_sri() {
  local json="$1"
  local asset="$2"
  local digest

  digest="$(
    jq -r --arg name "$asset" '.assets[] | select(.name==$name) | .digest' \
      <<<"$json" | head -n 1
  )"
  if [[ -z "$digest" || "$digest" == "null" ]]; then
    echo "error: missing sha256 digest for $asset" >&2
    exit 1
  fi
  if [[ "${digest#sha256:}" == "$digest" ]]; then
    echo "error: unexpected digest format for $asset: $digest" >&2
    exit 1
  fi

  nix hash convert --hash-algo sha256 "${digest#sha256:}"
}

linux_arm="$(digest_sri "$linux_json" "helium-${version}-arm64_linux.tar.xz")"
linux_x86="$(digest_sri "$linux_json" "helium-${version}-x86_64_linux.tar.xz")"
mac_arm="$(digest_sri "$mac_json" "helium_${version}_arm64-macos.dmg")"
mac_x86="$(digest_sri "$mac_json" "helium_${version}_x86_64-macos.dmg")"

perl -0pi -e 'my $c = s/(version = ")[^"]+(")/$1'"$version"'$2/s; die "error: version not updated\n" if $c != 1;' \
  flake.nix

update_hash_block() {
  local repo="$1"
  local arm_hash="$2"
  local x86_hash="$3"

  REPO="$repo" ARM="$arm_hash" X86="$x86_hash" perl -0pi -e '
    my $repo = $ENV{REPO};
    my $arm = $ENV{ARM};
    my $x86 = $ENV{X86};
    my $pattern = qr{
      (url = "https://github.com/imputnet/\Q$repo\E[^"]+";\n)
      (\s+)sha256 =\n
      \2  if isAarch64 then\n
      \2    "sha256-[^"]+"\n
      \2  else\n
      \2    "sha256-[^"]+";
    }xs;
    my $c = s/$pattern/${1}${2}sha256 =\n$2  if isAarch64 then\n$2    "$arm"\n$2  else\n$2    "$x86";/s;
    die "error: missing hash block for $repo\n" if $c != 1;
  ' flake.nix
}

update_hash_block "helium-macos" "$mac_arm" "$mac_x86"
update_hash_block "helium-linux" "$linux_arm" "$linux_x86"
