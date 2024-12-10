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

          # Step 1: Build the FHS environment (similar to your myFhs)
          myFhs = pkgs.buildFHSUserEnv {
            name = "fhs-python-env";
            targetPkgs = pkgs: (with pkgs; [
              python311
              uv
            ]);

            # Set LD_LIBRARY_PATH for the FHS Python
            profileHook = ''
              export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.openssl.out}/lib:${pkgs.bzip2}/lib:${pkgs.libffi}/lib:${pkgs.ncurses}/lib:${pkgs.readline}/lib:${pkgs.xz}/lib:$LD_LIBRARY_PATH
            '';

            runScript = "bash";
          };

        in
        {
          # Expose the FHS environment as a package (optional)
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
              # Use the FHS environment in the devShell
              inputsFrom = [ myFhs ];

              # Set up nix-ld for dynamically linked executables inside .venv
              LD_LIBRARY_PATH = libPath;

              nativeBuildInputs = [
                pkgs.direnv
                nix-ld.packages.${system}.nix-ld
              ];

              shellHook = ''
                eval "$(direnv hook $0)"

                export PATH=${myFhs}/bin:$PATH

                # Create virtual environment using uv from myFhs
                if [[ ! -d .venv ]]; then
                  echo "Creating virtual environment..."
                  uv venv .venv
                  echo ".venv" >> .gitignore
                fi

                # Activate the virtual environment
                source .venv/bin/activate
              '';
            };
        }
      ) // {
      # Template for easy initialization
      templates = {
        python-fhs-uv-direnv = {
          path = ./.;
          description = "Python development environment with FHS, uv, and direnv";
        };
        default = self.templates.python-fhs-uv-direnv;
      };
    };
}
