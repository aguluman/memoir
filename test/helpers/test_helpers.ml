(** Test helpers used by many test files. *)

let contains s sub =
  try Str.search_forward (Str.regexp_string sub) s 0 >= 0 with _ -> false

let contains_substring = contains

let write_file path content =
  let oc = open_out path in
  output_string oc content;
  close_out oc

let read_file path =
  let ic = open_in path in
  let len = in_channel_length ic in
  let s = really_input_string ic len in
  close_in ic;
  s

let with_temp_dir ?(prefix = "memoir_test") f =
  let base = Filename.get_temp_dir_name () in
  let dir =
    Filename.concat base (Printf.sprintf "%s_%d" prefix (Random.bits ()))
  in
  Unix.mkdir dir 0o700;
  Fun.protect
    ~finally:(fun () ->
      let _ = Sys.command (Printf.sprintf "rm -rf %s" dir) in
      ())
    (fun () -> f dir)

let with_temp_file ?(prefix = "memoir") ?(suffix = "") dir f =
  let fname =
    Filename.concat dir
      (Printf.sprintf "%s_%d%s" prefix (Random.bits ()) suffix)
  in
  let oc = open_out fname in
  close_out oc;
  Fun.protect
    ~finally:(fun () -> try Sys.remove fname with _ -> ())
    (fun () -> f fname)

let assert_file_exists path =
  if Sys.file_exists path then ()
  else Alcotest.failf "Expected file %s to exist" path
