{
  description = "A flake to build EasyConnect for nix";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=18.03";
      flake = false;
    };
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgVersion = "7.6.7.7";
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
    in
    {
      packages.${system}.default =
        pkgs.stdenv.mkDerivation rec {
          name = "EasyConnect";
          pname = "EasyConnect";
          version = pkgVersion;
          src = pkgs.fetchurl {
            url = "https://github.com/jarod/easyconnect-nix/raw/gh-pages/assets/EasyConnect_x64_${pkgVersion}.deb";
            sha256 = "rmI8bcA1T/h6/vu3cN5QE7/ZQwUcmmU7k9twglOy8NM=";
            name = "EasyConnect_x64_7_6_7_7.deb";
          };
          unpackCmd = "dpkg -x $src .";
          sourceRoot = ".";

          dontConfigure = true;
          dontBuild = true;

          nativeBuildInputs = with pkgs; [
            dpkg
            autoPatchelfHook
            makeWrapper
          ];

          buildInputs = with pkgs;[
            pango
            cairo
            gtk2-x11
            dbus-glib
            xorg.libXtst
            xorg.libXdamage
            alsaLib
            libudev0-shim
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/usr $out/usr/share/ $out/usr/share/applications $out/usr/lib $out/usr/share/pixmaps

            cp -r usr/* $out/usr/
            chmod +x $out/usr/share/sangfor/EasyConnect/EasyConnect
            # fix the path in the desktop file
            substituteInPlace $out/usr/share/applications/${pname}.desktop \
                --replace /usr/ $out/usr/
            substituteInPlace $out/usr/lib/systemd/system/EasyMonitor.service \
                --replace /usr/ $out/usr/

            runHook postInstall
          '';

          preFixup =
            let
              runtimeLibs = lib.makeLibraryPath [ pkgs.libudev0-shim ];
            in
            ''
              wrapProgram "$out/usr/share/sangfor/EasyConnect/EasyConnect" --prefix LD_LIBRARY_PATH : ${runtimeLibs}
            '';

          meta = with lib; {
            description = "Sangfor SSL VPN";
            homepage = "https://www.sangfor.com/cybersecurity/products/ssl-vpn";
            platforms = [ "x86_64-linux" ];
            sourceProvenance = with sourceTypes; [ binaryNativeCode ];
            hydraPlatforms = [ ];
            # license = licenses.unfreeRedistributable;
            license = licenses.agpl3Plus;
            maintainers = with maintainers; [ jarod ];
          };
        }
      ;

    };
}
