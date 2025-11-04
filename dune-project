(lang dune 3.20)

(name memoir)

(version 0.1.0)

(generate_opam_files true)

(source
 (github aguluman/memoir))

(license GPL-3.0-only)

(authors "Chukwuma Akunyili")

(maintainers "Chukwuma Akunyili")

(homepage "https://github.com/aguluman/memoir")

(documentation "https://fearful-odds.rocks/docs")

(package
 (name memoir)
 (synopsis "An OCaml-powered memoir website and static site generator")
 (description
  "A modern portfolio and memoir website built with OCaml, featuring static site generation and interactive components")
 (depends
  (ocaml
   (>= 5.3.0))
  (dune
   (>= 3.18.0))
  (yaml
   (>= 3.0.0))
  (core_unix
   (>= 0.15.0))
  (tyxml
   (>= 4.5.0))
  (yojson
   (>= 2.2.0))
  (omd
   (>= 1.3.2))
  (dream
   (>= 1.0.0~alpha4))
  (alcotest :with-test)
  (qcheck :with-test)
  (qcheck-alcotest :with-test)))
