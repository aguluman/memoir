open Alcotest
open Test_helpers

(** Basic example of QCheck property-based test *)
let property_test_example =
  let open QCheck in
  [
    Test.make ~name:"String reversal is symmetric" string (fun s ->
        (* A better test for string symmetry that doesn't depend on spaces *)
        let reversed =
          String.init (String.length s) (fun i -> s.[String.length s - 1 - i])
        in
        let double_reversed =
          String.init (String.length reversed) (fun i ->
              reversed.[String.length reversed - 1 - i])
        in
        String.equal s double_reversed)
    |> QCheck_alcotest.to_alcotest;
  ]

let () =
  run "Memoir Tests"
    [
      ( "Basic tests",
        [
          test_case "Sample test" `Quick (fun () ->
              check bool "boolean equality" true true);
        ] );
      ("QCheck property tests", property_test_example);
    ]
