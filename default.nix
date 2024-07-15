{
  system,
  pkgs,
  lib ? pkgs.lib,
  stdenv ? pkgs.stdenv,
  crane,
  fenix,
  flake-utils,
  ...
}: let
  # fenix: rustup replacement for reproducible builds
  toolchain = fenix.${system}.fromToolchainFile {
    file = ./rust-toolchain.toml;
    sha256 = "sha256-opUgs6ckUQCyDxcB9Wy51pqhd0MPGHUVbwRKKPGiwZU=";
  };
  # crane: cargo and artifacts manager
  craneLib = crane.${system}.overrideToolchain toolchain;

  nativeBuildInputs = with pkgs; [
    worker-build
    wasm-pack
    wasm-bindgen-cli
    binaryen
  ];

  buildInputs = with pkgs; [
    openssl
    pkg-config
  ]
  ++ lib.optionals stdenv.buildPlatform.isDarwin [
    pkgs.libiconv
  ];
  # ++ lib.optionals stdenv.buildPlatform.isLinux [
  #   pkgs.libxkbcommon.dev
  # ];

  worker = name: craneLib.buildPackage {
    doCheck = false;
    pname = "newsletter";
    src = craneLib.cleanCargoSource (craneLib.path ./.);
    buildPhaseCargoCommand = "HOME=$(mktemp -d fake-homeXXXX) worker-build --release --mode no-install . -- -p crates/${name}";

    installPhaseCommand = ''
      cp -r ./build $out
    '';

    nativeBuildInputs = with pkgs; nativeBuildInputs ++ [
      esbuild
    ];

    inherit buildInputs;
  };
in
{
  # `nix build`
  packages = rec {
    default = api;
    api = worker "api";
    sendmail = worker "sendmail";
  };

  # `nix develop`
  devShells.default = craneLib.devShell {
    buildInputs = with pkgs; nativeBuildInputs
      ++ buildInputs ++ [
        cargo-make
      ];
    # pkgs.nodePackages.wrangler
  };
}
