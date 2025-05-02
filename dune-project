(lang dune 3.18)
(name memoir)
(version 0.1.0)

(generate_opam_files true)

(source (github aguluman/memoir))
(license GPL-3.0-only)
(authors "Chukwuma Akunyili")
(maintainers "Chukwuma Akunyili <chukwumaakunyili@gmail.com>")

(package
 (name memoir)
 (synopsis "OCaml portfolio website")
 (description "A personal portfolio website using OCaml for both frontend and backend")
 (depends
  (ocaml (>= 4.14.0))
  dream
  tyxml
  js_of_ocaml
  js_of_ocaml-ppx
  omd
  yaml
  lwt
  core
  (alcotest :with-test)
  (qcheck :with-test)))