{
  description = "bypass-paywalls — bypass paywalls on news sites";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-webext.url = "github:rivavolt/nix-webext";
  };

  outputs = { self, nixpkgs, nix-webext }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          manifest = builtins.fromJSON (builtins.readFile ./manifest.json);

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
        in
        # Chrome-only (no gecko id). Build feeds nix-webext the pre-assembled
        # `extension`; nix-webext emits the keyless external-extension manifest
        # (CRX signed at activation). extId is the stable Chrome ID the old
        # committed key derived.
        nix-webext.lib.mkBrowserExtension {
          inherit pkgs extension;
          pname = "bypass-paywalls";
          version = manifest.version;
          extId = "diaohonmkmppbdanbkdmodchdmhehodi";
          firefox = false;
          transformManifest = false;
        });
    };
}
