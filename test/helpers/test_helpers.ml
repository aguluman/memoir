(** Test helpers for the Memoir project *)

(** Common test utilities *)
module Common = struct
  (** Create a temporary file with the given content *)
  let with_temp_file content f =
    let temp_file = Filename.temp_file "memoir_test" ".tmp" in
    let oc = open_out temp_file in
    output_string oc content;
    close_out oc;
    try
      let result = f temp_file in
      Sys.remove temp_file;
      result
    with e ->
      Sys.remove temp_file;
      raise e

  (** Test that an exception is raised *)
  let expect_exception f =
    try
      ignore (f ());
      false
    with _ -> true
end

(** QCheck helpers for property-based testing *)
module Property = struct
  open QCheck

  (** Common generators *)
  let string_gen = string

  let small_string_gen = string_of_size Gen.small_nat
  let alphanum_string_gen = string_of Gen.printable

  (** Run QCheck tests with Alcotest *)
  let run_tests tests = List.map QCheck_alcotest.to_alcotest tests
end
