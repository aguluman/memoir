(* Configuration *)
let port = 8080
let host = "127.0.0.1"
let static_dir = "_site"
let static_subdir = Filename.concat static_dir "static"

(* Helper function to read file content *)
let read_file path =
  let ic = open_in_bin path in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  content

(* Path normalization to prevent directory traversal *)
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

(* Simple Dream server for development *)
let start_server () =
  let handler req =
    let uri = Dream.target req in
    (* Remove leading slash and normalize path *)
    let clean_path =
      if uri = "/" then "pages/index"
      else String.sub uri 1 (String.length uri - 1)
    in
    let normalized_path = normalize_path clean_path in

    (* Try static subdirectory first, then fall back to root *)
    let possible_paths =
      [
        Filename.concat static_subdir normalized_path;
        Filename.concat static_dir normalized_path;
      ]
    in

    let rec try_paths = function
      | [] -> Lwt.return (Dream.response ~code:404 "Not Found")
      | path :: rest ->
          let final_path =
            if Sys.file_exists path then
              if Sys.is_directory path then
                let index_path = Filename.concat path "index.html" in
                if Sys.file_exists index_path then index_path else path
              else path
            else
              (* Try adding .html extension for clean URLs *)
              let html_path = path ^ ".html" in
              let dir_index = Filename.concat path "index.html" in
              if Sys.file_exists html_path then html_path
              else if Sys.file_exists dir_index then dir_index
              else path
          in

          if Sys.file_exists final_path && not (Sys.is_directory final_path)
          then
            let content_type =
              match Filename.extension final_path with
              | ".html" -> "text/html; charset=utf-8"
              | ".css" -> "text/css"
              | ".js" -> "application/javascript"
              | ".json" -> "application/json"
              | ".png" -> "image/png"
              | ".jpg" | ".jpeg" -> "image/jpeg"
              | ".gif" -> "image/gif"
              | ".svg" -> "image/svg+xml"
              | ".woff" -> "font/woff"
              | ".woff2" -> "font/woff2"
              | ".ttf" -> "font/ttf"
              | ".eot" -> "application/vnd.ms-fontobject"
              | ".ico" -> "image/x-icon"
              | _ -> "application/octet-stream"
            in
            try
              let content = read_file final_path in
              Lwt.return
                (Dream.response
                   ~headers:[ ("Content-Type", content_type) ]
                   content)
            with _ ->
              Lwt.return (Dream.response ~code:500 "Internal Server Error")
          else try_paths rest
    in
    try_paths possible_paths
  in

  print_endline (Printf.sprintf "Starting server at http://%s:%d/" host port);
  print_endline "Press Ctrl+C to stop the server.";
  Dream.run ~port @@ Dream.logger @@ Dream.router [ Dream.get "/**" handler ]

(* Entry point *)
let () =
  print_endline "Memoir Development Server - OCaml Static Site Generator";
  start_server ()
