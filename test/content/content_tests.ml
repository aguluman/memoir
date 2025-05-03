open Alcotest
open Test_helpers

let test_placeholder () = check bool "placeholder test" true true

let () =
  run "Content Component Tests"
    [
      ( "Markdown parsing",
        [ test_case "Placeholder test" `Quick test_placeholder ] );
      ( "Frontmatter extraction",
        [ test_case "Placeholder test" `Quick test_placeholder ] );
    ]
