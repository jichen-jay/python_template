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
            config = {
              allowUnfree = true;
            };
          };
          # Create an FHS environment specifically for Python
          python-fhs-env = pkgs.buildFHSEnv {
            name = "python-fhs-env";

            # Install Python and uv into the FHS environment
            targetPkgs = pkgs: [ pkgs.uv ];

            profileHook = ''
              export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.openssl.out}/lib:${pkgs.bzip2}/lib:${pkgs.libffi}/lib:${pkgs.ncurses}/lib:${pkgs.readline}/lib:${pkgs.xz}/lib

              export PATH=${pkgs.stdenv.cc.cc.lib}/lib:$PATH
            '';

            runScript = "bash";
          };

        in
        {
          packages.python-fhs = python-fhs-env;
          packages.direnv = pkgs.direnv;

          devShells.default =
            let
              libPath = pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc
                pkgs.zlib
                pkgs.openssl
                pkgs.bzip2
                pkgs.libffi
                pkgs.ncurses
                pkgs.readline
                pkgs.xz
              ];
              fhsPython = python-fhs-env;
            in
            pkgs.mkShell {
              # Set up nix-ld
              LD_LIBRARY_PATH = libPath;
              # Inherit the FHS environment
              inputsFrom = [ fhsPython ];
              # Bring in nix-ld
              nativeBuildInputs = [
                nix-ld.packages.${system}.nix-ld
                pkgs.direnv
              ];

              shellHook = ''
                eval "$(direnv hook $0)"

                # Set up the virtual environment inside the FHS environment
                if [[ ! -d .venv ]]; then
                  echo "Creating virtual environment..."
                  # Use uv from the FHS environment to create the virtual environment
                  uv venv .venv

                  echo ".venv" >> .gitignore
                  echo "Virtual environment created in .venv"
                fi

                # Source to activate, but then...
                source .venv/bin/activate
                # Unset VIRTUAL_ENV and remove .venv/bin from PATH
                unset VIRTUAL_ENV
                export PATH=$(echo "$PATH" | sed -E "s|${builtins.replaceStrings [":"] [" "] ./.venv/bin}||")
                # Make sure the FHS environment's python takes priority on PATH
                export PATH=${fhsPython}/bin:$PATH
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

