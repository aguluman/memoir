open Alcotest
open Test_helpers

(** Test placeholder functionality *)
let test_placeholder () = check bool "placeholder test" true true

(** Test basic string operations *)
let test_string_operations () =
  let test_string = "Hello, World!" in
  check string "String length test" test_string test_string;
  check bool "String contains test" true (String.length test_string > 0)

let () =
  run "Static Site Generator Tests"
    [
      ( "File operations",
        [
          test_case "Placeholder test" `Quick test_placeholder;
          test_case "String operations" `Quick test_string_operations;
        ] );
    ]
