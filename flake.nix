{
  description = "A best script!";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # Common build inputs
        commonBuildInputs = with pkgs; [
          ruby_3_2
          surge-cli
        ];

        # Helper function to create scripts
        mkScript =
          name:
          (pkgs.writeScriptBin name (builtins.readFile ./bin/${name})).overrideAttrs (old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });

        # Helper function to create packages
        mkPackage =
          name:
          pkgs.symlinkJoin {
            inherit name;
            paths = [ (mkScript name) ] ++ commonBuildInputs;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
          };

        # Script names
        scripts = [
          "build"
          "serve"
          "push"
        ];

        # Generate all packages
        scriptPackages = builtins.listToAttrs (
          map (name: {
            inherit name;
            value = mkPackage name;
          }) scripts
        );

      in
      rec {
        defaultPackage = packages.serve;
        packages = scriptPackages;

        devShells = rec {
          default = dev;
          dev = pkgs.mkShell {
            buildInputs = commonBuildInputs ++ (builtins.attrValues packages);
          };
        };
      }
    );
}
