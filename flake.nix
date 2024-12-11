{
  description = "Python development environment with FHS, uv, and direnv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-ld.url = "github:Mic92/nix-ld";
  };

  outputs = { self, nixpkgs, flake-utils, nix-ld }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          myFhs = pkgs.buildFHSEnv {
            name = "fhs-env";
            targetPkgs = pkgs: with pkgs; [
              stdenv.cc.cc.lib
              zlib
              openssl
              bzip2
              libffi
              ncurses
              readline
              xz
              glib
              sqlite
              expat
              python311Full
            ];
            profileHook = ''
              export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.openssl.out}/lib:${pkgs.bzip2}/lib:${pkgs.libffi}/lib:${pkgs.ncurses}/lib:${pkgs.readline}/lib:${pkgs.xz}/lib:$LD_LIBRARY_PATH
            '';
            runScript = "bash";
          };

        in
        {
          packages.myFhs = myFhs;
          packages.direnv = pkgs.direnv;
          packages.default = myFhs;

          devShells.default =
            let
              # Libraries for nix-ld
              ldLibraries = with pkgs; [
                stdenv.cc.cc
                zlib
                openssl
                bzip2
                libffi
                ncurses
                readline
                xz
                glib
                sqlite
                expat
                python311Full
              ];

              # Generate LD_LIBRARY_PATH for nix-ld
              libPath = pkgs.lib.makeLibraryPath ldLibraries;

            in
            pkgs.mkShell {
              # Inherit FHS environment
              inputsFrom = [ myFhs ];

              # Set up nix-ld
              LD_LIBRARY_PATH = libPath;

              nativeBuildInputs = [
                pkgs.python311Full
                pkgs.uv
                nix-ld.packages.${system}.nix-ld
                pkgs.direnv
                # pkgs.python311Packages.pip
                # pkgs.python311Packages.numpy
                # pkgs.python311Packages.virtualenv
              ];

              shellHook = ''
                export PATH=${myFhs}/bin:$PATH
                if [ ! -d ".venv" ]; then
                  uv venv -p ${pkgs.python311Full}/bin/python .venv
                fi
                source .venv/bin/activate
              '';
            };
        }
      ) // {
      templates = {
        python-fhs-uv-direnv = {
          path = ./.;
          description = "Python development environment with FHS, uv, and direnv";
        };
        default = self.templates.python-fhs-uv-direnv;
      };
    };
}
