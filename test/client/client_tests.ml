open Alcotest
open Test_helpers

let test_placeholder () = check bool "placeholder test" true true

let () =
  run "Client-Side JS Component Tests"
    [
      ( "Interactive features",
        [ test_case "Placeholder test" `Quick test_placeholder ] );
      ( "DOM manipulation",
        [ test_case "Placeholder test" `Quick test_placeholder ] );
    ]
