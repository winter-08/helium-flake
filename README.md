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

The Helium Linux and macOS release pins get automatically updated each Monday
via a GitHub workflow.

To manually update to the newest Helium release:

1. Run `nix-shell update-helium.nu`

2. Test the build:

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
