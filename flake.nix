{
  description = "Python Development Environment with PyTorch (CPU) and uv";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    flake-parts.url = "github:hercules-ci/flake-parts";
    uv = {
      url = "github:astral-sh/uv/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-parts
    , uv
    , ...
    } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      perSystem =
        { pkgs
        , lib
        , system
        , self'
        , ...
        }: {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              python311

              uv.packages.${system}.default
            ];

            shellHook = ''
              echo "Creating virtual environment..."
              uv venv .venv
              echo "Activating virtual environment..."
              source .venv/bin/activate
              echo "Installing specific CPU-only PyTorch wheels..."
              uv pip install https://download.pytorch.org/whl/cpu/torch-2.1.2%2Bcpu-cp311-cp311-linux_x86_64.whl
              uv pip install https://download.pytorch.org/whl/cpu/torchvision-0.16.2%2Bcpu-cp311-cp311-linux_x86_64.whl
              echo "Installing dependencies from requirements.txt (if any)..."
              uv pip install -r requirements.txt || true
              echo "Environment setup complete!"
            '';
          };
        };

      # Define templates
      templates = {
        # General Python template
        python-dev = {
          path = ./.;
          description = "Python development environment with PyTorch (CPU) and uv";
          welcomeText = ''
            # Python Development Environment
          '';
        };

        # Default template (points to python-dev)
        default = self.templates.python-dev;
      };
    };
}
