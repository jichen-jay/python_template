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

          # FHS environment (only libraries, no Python)
          myFhs = pkgs.buildFHSUserEnv {
            name = "fhs-env";
            targetPkgs = pkgs: with pkgs; [
              # Only libraries required for a dynamically linked Python to run
              stdenv.cc.cc.lib
              zlib
              openssl
              bzip2
              libffi
              ncurses
              readline
              xz
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
              ];

              shellHook = ''
                eval "$(direnv hook $0)"
                # Add FHS environment to PATH
                export PATH=${myFhs}/bin:$PATH
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
