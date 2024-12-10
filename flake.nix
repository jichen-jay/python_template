{
  description = "Template for Python Development Environment (FHS, uv, direnv)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Consider pinning to a stable release
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

          # FHS Environment setup directly in flake.nix
          python-fhs-env = pkgs.buildFHSEnv {
            name = "python-fhs-env";
            targetPkgs = pkgs: (with pkgs; [
              python311
              # (Optional) any other packages you need in the FHS environment
            ]);

            # Adjust library paths as needed. Also take suggestions from "nix-ld --list"
            profileSetup = ''
              export NIX_LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib
              # Add other Linux-specific libraries
              export NIX_LD_LIBRARY_PATH+=${pkgs.zlib}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.openssl}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.bzip2}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.libffi}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.ncurses}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.readline}/lib
              export NIX_LD_LIBRARY_PATH+=${pkgs.xz}/lib
            '';

            runScript = "bash"; # Or your preferred shell
          };
        in
        {
          packages.default = python-fhs-env;

          devShells.default = pkgs.mkShell {
            # Inherit the FHS environment
            inputsFrom = [ python-fhs-env ];

            # Other development tools
            packages = with pkgs; [
              uv
              # ... other tools
            ];
          };
        }) // {
      # Put the templates outside `eachDefaultSystem` to make it available to `nix flake init -t`
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
    };
}
