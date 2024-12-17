{

  description = "A best script!";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:

    flake-utils.lib.eachDefaultSystem (
      system:

      let
        pkgs = import nixpkgs { inherit system; };
        serveName = "serve";
        pushName = "push";
        buildInputs = with pkgs; [
          ruby_3_2
          rubyPackages_3_2.minima
          jekyll
          surge-cli
        ];
        serveScript = (pkgs.writeScriptBin serveName (builtins.readFile ./bin/serve)).overrideAttrs (old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
        pushScript = (pkgs.writeScriptBin pushName (builtins.readFile ./bin/push)).overrideAttrs (old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
      in
      rec {
        defaultPackage = packages.serveScript;
        packages.serveScript = pkgs.symlinkJoin {
          name = serveName;
          paths = [ serveScript ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${serveName} --prefix PATH : $out/bin";
        };
        packages.pushScript = pkgs.symlinkJoin {
          name = pushName;
          paths = [ pushScript ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${pushName} --prefix PATH : $out/bin";
        };
        devShell = pkgs.mkShell {
          buildInputs = buildInputs ++ [
            packages.serveScript
            packages.pushScript
          ];
        };
      }
    );

}
