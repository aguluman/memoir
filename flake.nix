{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_3;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with ocamlPackages; [
            ocaml
            dune_3
            yaml
            tyxml
            omd
            dream
            # Test dependencies
            alcotest
            qcheck
            qcheck-alcotest
          ];
        };
      }
    );
}
