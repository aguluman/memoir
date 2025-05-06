open Alcotest
open Test_helpers

let test_placeholder () = check bool "placeholder test" true true

let () =
  run "Static Site Generator Tests"
    [
      ( "File operations",
        [ test_case "Placeholder test" `Quick test_placeholder ] );
      ( "Site generation",
        [ test_case "Placeholder test" `Quick test_placeholder ] );
    ]
