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
            targetPkgs = pkgs: [ pkgs.python311 ];
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
          packages.default = pkgs.writeShellScriptBin "init" ./init.sh;

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.direnv
              python-fhs-env
              pkgs.uv
            ];
            shellHook = ''
              eval "$(direnv hook $0)"
              # Create the virtual environment using uv
              if [[ ! -d .venv ]]; then
                echo "Creating virtual environment..."
                uv venv .venv
                echo ".venv" >> .gitignore
              fi

              # Activate the virtual environment
              source .venv/bin/activate
            '';
          };
        });
}
