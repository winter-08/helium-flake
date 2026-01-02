# helium-flake

A nix flake for [Helium](https://github.com/imputnet/helium), a private, fast, and honest web browser

## Usage

### Run directly

```bash
nix run github:amaanq/helium-flake
```

### Install to profile

```bash
nix profile install github:amaanq/helium-flake
```

### Add to NixOS configuration

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    nixosConfigurations.yourhost = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [
            inputs.helium.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

### Add to nix-darwin configuration

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    darwinConfigurations.yourhost = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # or "x86_64-darwin"
      modules = [
        {
          environment.systemPackages = [
            inputs.helium.packages.aarch64-darwin.default
          ];
        }
      ];
    };
  };
}
```

### Build locally

```bash
git clone git@github.com:amaanq/helium-flake.git
cd helium-flake
nix build
./result/bin/helium
```

## Supported Platforms

- x86_64-linux
- aarch64-linux
- x86_64-darwin
- aarch64-darwin

## Updating

To update to a new Helium release:

1. Check the latest releases and update the version in `flake.nix`:
   - [Linux releases](https://github.com/imputnet/helium-linux/releases)
   - [macOS releases](https://github.com/imputnet/helium-macos/releases)

   ```nix
   version = "0.7.7.1";  # Update this
   ```

2. Fetch the new hashes for all architectures:

   ```bash
   # Linux x86_64
   nix-prefetch-url https://github.com/imputnet/helium-linux/releases/download/VERSION/helium-VERSION-x86_64_linux.tar.xz
   nix hash convert --hash-algo sha256 --to sri <hash-from-above>

   # Linux aarch64
   nix-prefetch-url https://github.com/imputnet/helium-linux/releases/download/VERSION/helium-VERSION-arm64_linux.tar.xz
   nix hash convert --hash-algo sha256 --to sri <hash-from-above>

   # macOS x86_64
   nix-prefetch-url https://github.com/imputnet/helium-macos/releases/download/VERSION/helium_VERSION_x86_64-macos.dmg
   nix hash convert --hash-algo sha256 --to sri <hash-from-above>

   # macOS aarch64
   nix-prefetch-url https://github.com/imputnet/helium-macos/releases/download/VERSION/helium_VERSION_arm64-macos.dmg
   nix hash convert --hash-algo sha256 --to sri <hash-from-above>
   ```

3. Update the `sha256` values in `flake.nix` for all architectures in `linuxHashes` and `darwinHashes`

4. Test the build:

   ```bash
   # If you're on Linux

   nix build .#packages.x86_64-linux.helium
   ./result/bin/helium --version

   nix build .#packages.aarch64-linux.helium
   ./result/bin/helium --version

   # If you're on macOS

   nix build .#packages.x86_64-darwin.helium
   ./result/bin/helium --version

   nix build .#packages.aarch64-darwin.helium
   ./result/bin/helium --version
   ```

## License

GPL-3.0 (following upstream)
