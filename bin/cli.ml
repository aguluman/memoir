open Memoir_lib

(* Command line interface for the memoir tool *)
let help_text =
  "\n\
   Memoir - An OCaml-powered memoir website and static site generator\n\n\
   Usage:\n\
  \  memoir-cli generate    Generate the static site\n\
  \  memoir-cli serve       Start a development server\n\
  \  memoir-cli help        Show this help message\n\n\
   Options:\n\
  \  --output DIR  Specify output directory (default: _site)\n\
  \  --port NUM    Specify server port (default: 8080)\n\
  \  --help        Show this help message\n"

let () =
  let args = Array.to_list Sys.argv in
  match List.tl args with
  | [ "generate" ] ->
      print_endline "Starting site generation...";
      Sys.command "memoir-generator" |> ignore
  | [ "serve" ] ->
      print_endline "Starting development server...";
      Sys.command "memoir-server" |> ignore
  | [ "help" ] | [] | [ "--help" ] -> print_endline help_text
  | cmd :: _ ->
      Printf.eprintf "Unknown command: %s\n" cmd;
      print_endline help_text;
      exit 1
