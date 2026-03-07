{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          extension = pkgs.stdenv.mkDerivation {
            pname = "bypass-paywalls";
            version = "0-unstable";
            src = self;
            dontBuild = true;
            installPhase = ''
              mkdir -p $out/share/chromium-extension
              cp -r background.js contentScript.js contentScript_once.js contentScript_once_var.js \
                    sites.js sites_updated.json manifest.json \
                    bypass.png bypass-dark.png \
                    options custom lib \
                    $out/share/chromium-extension/
            '';
          };

          manifest = builtins.fromJSON (builtins.readFile "${extension}/share/chromium-extension/manifest.json");

          extId = builtins.readFile (pkgs.runCommand "bypass-paywalls-ext-id" {
            nativeBuildInputs = [ pkgs.python3 pkgs.openssl ];
          } ''
            python3 ${./nix/crx-id.py} ${./keys/signing.pem} > $out
          '');

          crx = pkgs.runCommand "bypass-paywalls-crx" {
            nativeBuildInputs = [ pkgs.python3 pkgs.openssl ];
          } ''
            mkdir -p $out
            python3 ${./nix/pack-crx3.py} ${extension}/share/chromium-extension ${./keys/signing.pem} $out/extension.crx
          '';

        in {
          inherit extension;
          default = pkgs.linkFarm "bypass-paywalls" [
            { name = "share/chromium/extensions/${extId}.json";
              path = pkgs.writeText "${extId}.json" (builtins.toJSON {
                external_crx = "${crx}/extension.crx";
                external_version = manifest.version;
              });
            }
          ];
        });
    };
}
