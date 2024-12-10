# flake.nix
{
  description = "Python development environment with FHS, uv, and direnv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          python-fhs-env = pkgs.buildFHSEnv {
            name = "python-fhs-env";
            profileSetup = ''
              export NIX_LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.zlib}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.openssl}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.bzip2}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.libffi}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.ncurses}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.readline}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.xz}/lib
            '';
            runScript = "bash";
          };
        in
        {
          packages.python-fhs = python-fhs-env;
          packages.uv = pkgs.uv;
          packages.direnv = pkgs.direnv;

          devShells.default = pkgs.mkShell {
            # Use the FHS environment as the base
            inputsFrom = [ python-fhs-env ];

            # No need to add to `buildInputs` if the package is already in `targetPkgs`.
            buildInputs = [
              pkgs.direnv
            ];

            shellHook = ''
              eval "$(direnv hook $0)"

              # Create and set up the virtual environment if it doesn't exist.
              if [[ ! -d .venv ]]; then
                echo "Creating virtual environment..."
                # Use uv inside the FHS environment to create the venv
                uv venv .venv

                # Set up .gitignore
                echo ".venv" >> .gitignore

                echo "Virtual environment created in .venv"
              fi

              # Load the virtual environment
              source .venv/bin/activate
            '';
          };
        }) // {
      # Templates
      templates = {
        python-fhs-uv-direnv = {
          path = ./.;
          description = "Python development environment with FHS, uv, and direnv";
          welcomeText = ''
            # Python Development Environment (FHS, uv, direnv)
          '';
        };
        default = self.templates.python-fhs-uv-direnv;
      };
    }; # Add the missing closing brace
}
