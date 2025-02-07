# SPDX-FileCopyrightText: 2025 Joost van der Laan <joost@fashionunited.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

{
  description = "A Nix-flake-based Rust development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default self.overlays.default ];
          config = {
            allowUnfree = true;
          };
        };
      });
    in
    {
      overlays.default = final: prev: {
        rustToolchain =
          let
            rust = prev.rust-bin;
          in
          if builtins.pathExists ./rust-toolchain.toml then
            rust.fromRustupToolchainFile ./rust-toolchain.toml
          else if builtins.pathExists ./rust-toolchain then
            rust.fromRustupToolchainFile ./rust-toolchain
          else
            rust.nightly.latest.default.override {
              extensions = [ "rust-src" "rustfmt" ];
              targets = [ "wasm32-wasip1" "wasm32-unknown-unknown" ];
            };
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            rustToolchain
            openssl
            pkg-config
            cargo-deny
            cargo-edit
            cargo-watch
            rust-analyzer
            surrealdb
              surrealdb-migrations 
              cargo-leptos
              # pkgsUnstable.fermyon-spin
            pkgs.nodePackages.tailwindcss
              pkgs.nodePackages.postcss
              pkgs.nodePackages.autoprefixer
          ];

          env = {
            # Required by rust-analyzer
            RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
          };
        };
      });
    };
}


# {
#   description = "Development environment for my-leptos-app";

#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#     rust-overlay.url = "github:oxalica/rust-overlay";
#     flake-utils.url = "github:numtide/flake-utils";
#     crane.url = "github:ipetkov/crane";
#   };

#   outputs = { self, nixpkgs, rust-overlay, flake-utils, crane, ... }:
#     flake-utils.lib.eachDefaultSystem (system:
#       let

#         pkgsUnstable = import nixpkgs {
#           inherit system;
#         };
        
#         overlays = [ (import rust-overlay) ];
#         pkgs = import nixpkgs {
#           inherit system overlays;
#           config = {
#             allowUnfree = true;
#           };
#         };
        
#         # Latest nightly Rust
#         rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
#           extensions = [ "rust-src" "rust-analyzer" "clippy" "llvm-tools-preview" "rust-std"];
#           targets = [ "wasm32-wasip1" "wasm32-unknown-unknown" ];
#         };

#         # this is how we can tell crane to use our toolchain!
#         craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
#         # cf. https://crane.dev/API.html#libcleancargosource
#         src = craneLib.cleanCargoSource ./.;
#         # as before
#         nativeBuildInputs = with pkgs; [ rustToolchain pkg-config gcc ];
#         buildInputs = with pkgs; [ 
#           openssl 
#           fontconfig 
#           ] ++ lib.optionals pkgs.stdenv.isDarwin [
#             # Additional darwin specific inputs can be set here
#             pkgs.libiconv
#             pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
#         #   darwin.apple_sdk.frameworks.Security
#         #   darwin.apple_sdk.frameworks.CoreServices
#         #   darwin.apple_sdk.frameworks.CoreFoundation
#         #   darwin.apple_sdk.frameworks.SystemConfiguration
#         ];
#         # because we'll use it for both `cargoArtifacts` and `bin`
#         commonArgs = {
#           inherit src buildInputs nativeBuildInputs;
#         };
#         cargoArtifacts = craneLib.buildDepsOnly commonArgs;
#         # remember, `set1 // set2` does a shallow merge:
#         bin = craneLib.buildPackage (commonArgs // {
#           inherit cargoArtifacts;
#         });
#       in
#       {
#          packages =
#             {
#               # that way we can build `bin` specifically,
#               # but it's also the default.
#               inherit bin;
#               default = bin;
#             };

#         devShells.default = pkgs.mkShell {
#           # instead of passing `buildInputs` / `nativeBuildInputs`,
#             # we refer to an existing derivation here
#             inputsFrom = [ bin ];
#             buildInputs = with pkgs; [ 
#               reuse 
#               clippy-sarif 
#               sarif-fmt 
#               sqlite 
#               sqlx-cli
#               surrealdb
#               surrealdb-migrations 
#               cargo-leptos
#               pkgsUnstable.fermyon-spin
#               gcc
#               gnumake
#               nodejs_22
#               pkgs.nodePackages.tailwindcss
#               pkgs.nodePackages.postcss
#               pkgs.nodePackages.autoprefixer
#             ];

#           # Environment variables
#           shellHook = ''
#             echo "🦀 Welcome to the my-leptos-app development environment!"
#             # export LIBRARY_PATH="/usr/lib:$LIBRARY_PATH"
#             # export CPATH="/usr/include:$CPATH"
#             # export RUSTFLAGS="-L /usr/lib"
#             # export NIX_LDFLAGS="-L/usr/lib -liconv $NIX_LDFLAGS"
#           '';
#         };
#       }
#     );
# }