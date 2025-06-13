{
  pkgs,
  lib ? pkgs.lib,
  stdenv ? pkgs.stdenv,
  crane,
  fenix,
  wrangler-fix,
  ...
}: let
  # fenix: rustup replacement for reproducible builds
  toolchain = fenix.fromToolchainFile {
    file = ./rust-toolchain.toml;
    sha256 = "sha256-KUm16pHj+cRedf8vxs/Hd2YWxpOrWZ7UOrwhILdSJBU=";
  };
  # crane: cargo and artifacts manager
  craneLib = crane.overrideToolchain toolchain;

  nativeBuildInputs = with pkgs; [
    worker-build
    wasm-pack
    wasm-bindgen-cli
    binaryen
  ];

  buildInputs = with pkgs;
    [
      openssl
      pkg-config
      autoPatchelfHook
    ]
    ++ lib.optionals stdenv.buildPlatform.isDarwin [
      pkgs.libiconv
    ];

  worker = name: craneLib.buildPackage {
    pname = name;
    doCheck = false;
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./Cargo.toml
        ./Cargo.lock
        ./crates/api
        ./crates/models
        ./crates/sendmail
      ];
    };
    buildPhaseCargoCommand = ''
      cd crates/${name}
      HOME=$(mktemp -d fake-homeXXXX) worker-build --release --mode no-install
      cd ../..
    '';

    # Custom build command is provided, so this should be enabled
    doNotPostBuildInstallCargoBinaries = true;

    installPhaseCommand = ''
      cp -r ./crates/${name}/build $out
    '';

    nativeBuildInputs = with pkgs; [esbuild] ++ nativeBuildInputs;

    inherit buildInputs;
  };

  both-workers = craneLib.buildPackage {
    pname = "newsletter";
    doCheck = false;
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./Cargo.toml
        ./Cargo.lock
        ./crates/api
        ./crates/models
        ./crates/sendmail
      ];
    };
    buildPhaseCargoCommand = ''
      cd crates/api
      HOME=$(mktemp -d fake-homeXXXX) worker-build --release --mode no-install
      cd ../..
      cd crates/sendmail
      HOME=$(mktemp -d fake-homeXXXX) worker-build --release --mode no-install
      cd ../..
    '';

    # Custom build command is provided, so this should be enabled
    doNotPostBuildInstallCargoBinaries = true;

    installPhaseCommand = ''
      mkdir -p $out
      cp -r ./crates/api/build $out/api
      cp -r ./crates/sendmail/build $out/sendmail
    '';

    nativeBuildInputs = with pkgs; [esbuild] ++ nativeBuildInputs;

    inherit buildInputs;
  };
in {
  # `nix build`
  packages.default = both-workers;

  # `nix build .#api`
  packages.api = worker "api";

  # `nix build .#sendmail`
  packages.sendmail = worker "sendmail";

  # `nix develop`
  devShells.default = craneLib.devShell {
    packages =
      nativeBuildInputs
      ++ buildInputs
      ++ [wrangler-fix.wrangler];
  };
}
