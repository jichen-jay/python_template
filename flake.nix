{
  description = "Template for Python Development Environment (FHS, uv, direnv)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Consider pinning to a stable release
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    # uv.url = "github:astral-sh/uv/main"; # Not needed if using nixpkgs version
    # uv.inputs.nixpkgs.follows = "nixpkgs"; # Not needed if using nixpkgs version
  };

  outputs = { self, nixpkgs, flake-parts, ... } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ]; # Specify your target systems

      perSystem = { pkgs, system, lib, ... }:
        let
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
            inputsFrom = [ python-fhs-env ];

            # Other development tools
            packages = with pkgs; [
              uv
              # ... other tools
            ];

          };
        };

      # Template definition
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
