{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-crx.url = "github:andreivolt/nix-crx";
  };

  outputs = { self, nixpkgs, nix-crx }:
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

          manifest = builtins.fromJSON (builtins.readFile ./manifest.json);

          crxPkg = nix-crx.lib.mkCrxPackage {
            inherit pkgs extension;
            key = ./keys/signing.pem;
            extId = "diaohonmkmppbdanbkdmodchdmhehodi";
            version = manifest.version;
          };

        in {
          inherit extension;
          default = crxPkg.package;
        });
    };
}
