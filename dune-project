(lang dune 3.18)

(name memoir)

(version 0.1.0)

(generate_opam_files true)

(source
 (github aguluman/memoir))

(license GPL-3.0-only)

(authors "Chukwuma Akunyili")

(maintainers "Chukwuma Akunyili <chukwumaakunyili@gmail.com>")

(homepage "https://github.com/aguluman/memoir")

(documentation "https://github.com/aguluman/memoir")

(package
 (name memoir)
 (synopsis "An OCaml-powered memoir website and static site generator")
 (description
  "A modern portfolio and memoir website built with OCaml, featuring static site generation and interactive components")
 (depends
  (ocaml
   (>= 5.3.0))
  dune
  (str
   (>= 1.0.0))
  (tyxml
   (>= 4.5.0))
  (omd
   (>= 1.3.2))
  ; Markdown parser
  (yaml
   (>= 3.0.0))
  ; For frontmatter parsing
  (yojson
   (>= 2.0.0))
  (lwt
   (>= 5.5.0))
  (js_of_ocaml
   (>= 4.0.0))
  (js_of_ocaml-ppx
   (>= 4.0.0))
  (js_of_ocaml-lwt
   (>= 4.0.0))
  (bigstringaf
   (>= 0.9.0))
  (threads
   (>= 0.0.0))
  (dream
   (>= 1.0.0~alpha4))
  (alcotest :with-test)
  (qcheck :with-test)
  (qcheck-alcotest :with-test)))
