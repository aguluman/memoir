(* Configuration *)
let port = 8080
let host = "127.0.0.1"
let static_dir = "_site"

(* Helper function to read file content *)
let read_file path =
  let ic = open_in_bin path in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  content

(* Simple Dream server for development *)
let start_server () =
  let handler req =
    let uri = Dream.target req in
    let path =
      if uri = "/" then Filename.concat static_dir "index.html"
      else Filename.concat static_dir (String.sub uri 1 (String.length uri - 1))
    in
    let path =
      if Sys.file_exists path && Sys.is_directory path then
        Filename.concat path "index.html"
      else path
    in
    if Sys.file_exists path then
      let content_type =
        match Filename.extension path with
        | ".html" -> "text/html"
        | ".css" -> "text/css"
        | ".js" -> "application/javascript"
        | ".json" -> "application/json"
        | ".png" -> "image/png"
        | ".jpg" | ".jpeg" -> "image/jpeg"
        | ".gif" -> "image/gif"
        | ".svg" -> "image/svg+xml"
        | _ -> "application/octet-stream"
      in
      (* Read the file content *)
      let content = read_file path in
      Dream.respond ~headers:[ ("Content-Type", content_type) ] content
    else (fun _ -> Dream.empty `Not_Found) req
  in
  print_endline (Printf.sprintf "Starting server at http://%s:%d/" host port);
  print_endline "Press Ctrl+C to stop the server.";
  Dream.run ~port @@ Dream.logger @@ Dream.router [ Dream.get "/**" handler ]

(* Entry point *)
let () =
  print_endline "Memoir Development Server - OCaml Static Site Generator";
  start_server ()
