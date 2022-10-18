{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:rmourey26/flake-utils";
  };

  nixConfig = {
    extra-substituters = [
      "https://tbco.cachix.org"
    ];
    extra-trusted-public-keys = [
      "tbco.cachix.org-1:OYKDS3zfcsf4WEVuSTV+XmgaIn1GeclGW0kSFd3G0NU="
    ];
  };

  outputs = { self, nixpkgs, utils }:
    let
      workspaceCargo = builtins.fromTOML (builtins.readFile ./Cargo.toml);
      inherit (workspaceCargo.workspace) members;
    in utils.lib.simpleFlake {
      inherit nixpkgs;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      preOverlays = [ ];
      overlay = final: prev:
        let inherit (prev) lib;
        in (lib.listToAttrs (lib.forEach members (member:
          lib.nameValuePair member (prev.rustPlatform.buildRustPackage {
            inherit ((builtins.fromTOML
              (builtins.readFile (./. + "/${member}/Cargo.toml"))).package)
              name version;
            src = ./.;
            cargoSha256 = "0hzzsgbyj1wjw8aiywzdbccmzlcbxcq361xln21q118xk16xzlzp";
            buildFeatures = lib.optional (member == "quibitous") "prometheus-metrics";
            nativeBuildInputs = with final; [ pkg-config protobuf rustfmt ];
            buildInputs = with final; [ openssl ];
            PROTOC = "${final.protobuf}/bin/protoc";
            PROTOC_INCLUDE = "${final.protobuf}/include";
          })))) // {
            quibitous-entrypoint = let
              script = final.writeShellScriptBin "entrypoint" ''
                set -exuo pipefail

                ulimit -n 1024

                nodeConfig="$NOMAD_TASK_DIR/node-config.json"
                runConfig="$NOMAD_TASK_DIR/running.json"
                runYaml="$NOMAD_TASK_DIR/running.yaml"
                name="quibitous"

                chmod u+rwx -R "$NOMAD_TASK_DIR" || true

                function convert () {
                  chmod u+rwx -R "$NOMAD_TASK_DIR" || true
                  cp "$nodeConfig" "$runConfig"
                  remarshal --if json --of yaml "$runConfig" > "$runYaml"
                }

                if [ "$RESET" = "true" ]; then
                  echo "RESET is given, will start from scratch..."
                  rm -rf "$STORAGE_DIR"
                elif [ -d "$STORAGE_DIR" ]; then
                  echo "$STORAGE_DIR found, not restoring from backup..."
                else
                  echo "$STORAGE_DIR not found, restoring backup..."

                  restic restore latest \
                    --verbose=5 \
                    --no-lock \
                    --tag "$NAMESPACE" \
                    --target / \
                  || echo "couldn't restore backup, continue startup procedure..."
                fi

                set +x
                echo "waiting for $REQUIRED_PEER_COUNT peers"
                until [ "$(jq -e -r '.p2p.trusted_peers | length' < "$nodeConfig" || echo 0)" -ge $REQUIRED_PEER_COUNT ]; do
                  sleep 1
                done
                set -x

                convert

                if [ -n "$PRIVATE" ]; then
                  echo "Running with node with secrets..."
                  exec quibitous \
                    --storage "$STORAGE_DIR" \
                    --config "$NOMAD_TASK_DIR/running.yaml" \
                    --genesis-block $NOMAD_TASK_DIR/block0.bin/block0.bin \
                    --secret $NOMAD_SECRETS_DIR/bft-secret.yaml \
                    "$@" || true
                else
                  echo "Running with follower node..."
                  exec quibitous \
                    --storage "$STORAGE_DIR" \
                    --config "$NOMAD_TASK_DIR/running.yaml" \
                    --genesis-block $NOMAD_TASK_DIR/block0.bin/block0.bin \
                    "$@" || true
                fi
              '';
            in final.symlinkJoin {
              name = "entrypoint";
              paths = with final; [
                quibitous
                script

                bashInteractive
                coreutils
                curl
                diffutils
                fd
                findutils
                gnugrep
                gnused
                htop
                quibitous
                jq
                lsof
                netcat
                procps
                remarshal
                restic
                ripgrep
                strace
                tcpdump
                tmux
                tree
                utillinux
                vim
                yq
              ];
            };
          };

      packages = { quibitous, qcli, quibitous-entrypoint }@pkgs: pkgs;

      devShell =
        { mkShell, rustc, cargo, pkg-config, openssl, protobuf, rustfmt }:
        mkShell {
          PROTOC = "${protobuf}/bin/protoc";
          PROTOC_INCLUDE = "${protobuf}/include";
          buildInputs = [ rustc cargo pkg-config openssl protobuf rustfmt ];
        };

      hydraJobs = { quibitous, qcli, quibitous-entrypoint }@pkgs: pkgs;
    };
}
