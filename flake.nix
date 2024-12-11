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

          uvPackage = pkgs.stdenv.mkDerivation {
            pname = "uv";
            version = "0.5.8";
            src = pkgs.fetchurl {
              url = "https://github.com/astral-sh/uv/releases/download/0.5.8/uv-x86_64-unknown-linux-musl.tar.gz";
              sha256 = "1hmhh9p7vbrmd541rnkz5ijsrjsn2s9ra59s53wsgjxam7jwj0xm";
            };

            installPhase = ''
              mkdir -p $out/bin
              cp uv $out/bin/
              chmod +x $out/bin/uv
            '';
          };

          commonPackages = with pkgs; [
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

          myFhs = pkgs.buildFHSEnv {
            name = "my-fhs";
            targetPkgs = pkgs: commonPackages;
            runScript = "bash";
          };

        in
        {
          packages.myFhs = myFhs;
          packages.direnv = pkgs.direnv;
          packages.default = myFhs;

          devShells.default =
            let
              libPath = pkgs.lib.makeLibraryPath commonPackages;
            in
            pkgs.mkShell {
              inputsFrom = [ myFhs ];

              NIX_PATH = "
                nixpkgs=${nixpkgs}";
              PYTHONNOUSERSITE = "1";
              PYTHONDONTWRITEBYTECODE = "1";
              LD_LIBRARY_PATH = libPath;

              nativeBuildInputs = with pkgs; [
                python311Full
                uvPackage
                nix-ld.packages.${system}.nix-ld
                direnv
                black
                ruff
                mypy
                pylint
              ];

              shellHook = ''
                export PATH=${myFhs}/bin:$PATH
                export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath commonPackages}
  
                # Setup UV cache
                export UV_CACHE_DIR="$PWD/.cache/uv"
                mkdir -p "$UV_CACHE_DIR"
  
                # Create and activate venv if it doesn't exist
                if [ ! -d ".venv" ]; then
                  uv venv -p ${pkgs.python311Full}/bin/python .venv --system-site-packages
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
