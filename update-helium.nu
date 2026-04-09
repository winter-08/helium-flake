#!/usr/bin/env nix-shell
#! nix-shell -i nu -p nushell

def get-latest-release [repo: string] {
    let release = http get $"https://api.github.com/repos/($repo)/releases/latest"
    $release.tag_name
}

def get-helium-latest [] {
    let linux_version = get-latest-release "imputnet/helium-linux"
    let darwin_version = get-latest-release "imputnet/helium-macos"

    print $"Found latest Linux version: ($linux_version)"
    print $"Found latest macOS version: ($darwin_version)"

    let platforms = [
        { family: "linux", system: "x86_64-linux", repo: "helium-linux", version: $linux_version, file: $"helium-($linux_version)-x86_64_linux.tar.xz" }
        { family: "linux", system: "aarch64-linux", repo: "helium-linux", version: $linux_version, file: $"helium-($linux_version)-arm64_linux.tar.xz" }
        { family: "darwin", system: "x86_64-darwin", repo: "helium-macos", version: $darwin_version, file: $"helium_($darwin_version)_x86_64-macos.dmg" }
        { family: "darwin", system: "aarch64-darwin", repo: "helium-macos", version: $darwin_version, file: $"helium_($darwin_version)_arm64-macos.dmg" }
    ]

    let results = $platforms | each {|it|
        let url = $"https://github.com/imputnet/($it.repo)/releases/download/($it.version)/($it.file)"

        print $"Fetching ($it.system)."
        {
            family: $it.family
            system: $it.system
            version: $it.version
            url: $url
            sha256: (nix-prefetch-url $url | str trim)
        }
    }

    let linux = {
        version: $linux_version,
        hashes: {
            "x86_64-linux": ($results | where system == "x86_64-linux" | get sha256.0),
            "aarch64-linux": ($results | where system == "aarch64-linux" | get sha256.0),
        }
    }

    let darwin = {
        version: $darwin_version,
        hashes: {
            "x86_64-darwin": ($results | where system == "x86_64-darwin" | get sha256.0),
            "aarch64-darwin": ($results | where system == "aarch64-darwin" | get sha256.0),
        }
    }

    {
        linux: $linux,
        darwin: $darwin
    }
}

let versionData = get-helium-latest

print $versionData | table --expand

$versionData | to json | save helium-versions.json --force

print "Saved to helium-versions.json"
