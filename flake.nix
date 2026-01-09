{
  description = "Helium - A private, fast, and honest web browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs platforms;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          inherit (pkgs) lib stdenv;
          isDarwin = stdenv.isDarwin;
          isAarch64 = stdenv.hostPlatform.isAarch64;

          pname = "helium";
          version = "0.8.2.1";
          arch = if isAarch64 then "arm64" else "x86_64";
        in
        {
          helium =
            if isDarwin then
              pkgs.stdenv.mkDerivation {
                inherit pname version;

                src = pkgs.fetchurl {
                  url = "https://github.com/imputnet/helium-macos/releases/download/${version}/${pname}_${version}_${arch}-macos.dmg";
                  sha256 =
                    if isAarch64 then
                      "sha256-Y42Fj+5KPZ2aO7XazV1CFB7liAmWSsafcXpvukJRqoM="
                    else
                      "sha256-uDrsOxCo+FA/K3Ny+ycrjSClQ5gmu50K+9RC+td6yAE=";
                };

                dontUnpack = true;
                dontBuild = true;

                installPhase = ''
                  runHook preInstall

                  mkdir -p $out/Applications

                  mnt=$(mktemp -d)
                  /usr/bin/hdiutil attach $src -nobrowse -readonly -mountpoint "$mnt"
                  cp -r "$mnt/Helium.app" $out/Applications/
                  /usr/bin/hdiutil detach "$mnt"

                  runHook postInstall
                '';

                meta = {
                  inherit platforms;
                  description = "A private, fast, and honest web browser";
                  homepage = "https://github.com/imputnet/helium-macos";
                  license = lib.licenses.gpl3Only;
                  mainProgram = "Helium";
                  sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
                };
              }
            else
              pkgs.stdenv.mkDerivation {
                inherit pname version;

                src = pkgs.fetchurl {
                  url = "https://github.com/imputnet/helium-linux/releases/download/${version}/${pname}-${version}-${arch}_linux.tar.xz";
                  sha256 =
                    if isAarch64 then
                      "sha256-ymEQnVCAZN9SXIcVLEt6kNkkZ7USY0qBI9M1HsBkrrU="
                    else
                      "sha256-hljL7KlafD1TYPmA+U8HRdXKOUdsb6Lnk4XiAYfmPI8=";
                };

                nativeBuildInputs = [
                  pkgs.makeWrapper
                  pkgs.autoPatchelfHook
                  pkgs.qt6.wrapQtAppsHook
                ];

                buildInputs = [
                  pkgs.glib
                  pkgs.gdk-pixbuf
                  pkgs.gtk3
                  pkgs.nspr
                  pkgs.nss
                  pkgs.dbus
                  pkgs.atk
                  pkgs.at-spi2-atk
                  pkgs.cups
                  pkgs.expat
                  pkgs.libxcb
                  pkgs.libxkbcommon
                  pkgs.at-spi2-core
                  pkgs.xorg.libX11
                  pkgs.xorg.libXcomposite
                  pkgs.xorg.libXdamage
                  pkgs.xorg.libXext
                  pkgs.xorg.libXfixes
                  pkgs.xorg.libXrandr
                  pkgs.mesa
                  pkgs.cairo
                  pkgs.pango
                  pkgs.systemd
                  pkgs.alsa-lib
                  pkgs.libdrm
                  pkgs.qt6.qtbase
                ];

                # Ignore Qt5 shim, qt5webengine is unmaintained & we're using Qt6
                autoPatchelfIgnoreMissingDeps = [
                  "libQt5Core.so.5"
                  "libQt5Gui.so.5"
                  "libQt5Widgets.so.5"
                ];

                installPhase = ''
                  runHook preInstall

                  mkdir -p $out/bin $out/opt/helium
                  cp -r ./* $out/opt/helium/

                  makeWrapper $out/opt/helium/chrome-wrapper $out/bin/helium \
                    --prefix LD_LIBRARY_PATH : "${
                      lib.makeLibraryPath [
                        pkgs.libGL
                        pkgs.libva
                      ]
                    }"

                  mkdir -p $out/share/applications
                  cp $out/opt/helium/helium.desktop $out/share/applications/

                  mkdir -p $out/share/pixmaps
                  cp $out/opt/helium/product_logo_256.png $out/share/pixmaps/helium.png

                  runHook postInstall
                '';

                meta = {
                  inherit platforms;
                  description = "A private, fast, and honest web browser";
                  homepage = "https://github.com/imputnet/helium-linux";
                  license = lib.licenses.gpl3Only;
                  mainProgram = "helium";
                  sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
                };
              };

          default = self.packages.${system}.helium;
        }
      );
    };
}
