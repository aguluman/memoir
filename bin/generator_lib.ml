(* Library module exposing generator utility functions for testing *)

(* File utilities *)
let normalize_path path =
  let rec normalize acc = function
    | [] -> acc
    | "." :: rest -> normalize acc rest
    | ".." :: rest -> (
        match acc with
        | _ :: parent -> normalize parent rest
        | [] -> normalize [] rest)
    | x :: rest -> normalize (x :: acc) rest
  in
  let parts = Str.split (Str.regexp_string Filename.dir_sep) path in
  let normalized = normalize [] parts |> List.rev in
  String.concat Filename.dir_sep normalized

let ensure_directory_exists dir =
  let normalized_dir = normalize_path dir in
  try
    if not (Sys.file_exists normalized_dir) then
      let rec make_dir path =
        if not (Sys.file_exists path) then (
          make_dir (Filename.dirname path);
          Printf.printf "Creating directory: %s\n" path;
          Sys.mkdir path 0o755)
      in
      make_dir normalized_dir
    else if not (Sys.is_directory normalized_dir) then
      failwith
        (Printf.sprintf "%s exists but is not a directory" normalized_dir)
  with Sys_error msg ->
    failwith
      (Printf.sprintf "Failed to create directory %s: %s" normalized_dir msg)

(* File type detection *)
type file_type =
  | HTML
  | CSS
  | JavaScript
  | Image
  | Other

let determine_file_type path =
  match String.lowercase_ascii (Filename.extension path) with
  | ".html" | ".htm" -> HTML
  | ".css" -> CSS
  | ".js" -> JavaScript
  | ".png" | ".jpg" | ".jpeg" | ".gif" | ".svg" | ".webp" -> Image
  | _ -> Other

let read_file path =
  let normalized_path = normalize_path path in
  try
    let ic = open_in normalized_path in
    try
      let len = in_channel_length ic in
      let content = really_input_string ic len in
      close_in ic;
      content
    with e ->
      close_in ic;
      raise
        (Failure
           (Printf.sprintf "Failed to read file %s: %s" normalized_path
              (Printexc.to_string e)))
  with Sys_error msg ->
    raise
      (Failure (Printf.sprintf "Failed to open file %s: %s" normalized_path msg))

let write_file path content =
  let normalized_path = normalize_path path in
  try
    ensure_directory_exists (Filename.dirname normalized_path);
    Printf.printf "Writing file: %s\n" normalized_path;
    let oc = open_out normalized_path in
    try
      output_string oc content;
      close_out oc
    with e ->
      close_out oc;
      raise
        (Failure
           (Printf.sprintf "Failed to write to file %s: %s" normalized_path
              (Printexc.to_string e)))
  with Sys_error msg ->
    raise
      (Failure
         (Printf.sprintf "Failed to create file %s: %s" normalized_path msg))
