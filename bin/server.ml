(* Configuration *)
let port = 6060
let static_dir = "_site"
let static_subdir = Filename.concat static_dir "static"

(* Configuration for RSS feed generation *)
let rss_config =
  {
    Memoir_lib.site_title = "Chukwuma Akunyili's Website";
    site_description =
      "Thoughts on software engineering, functional programming, and technology";
    author = "Chukwuma Akunyili";
    base_url = Memoir_lib.site_domain;
    output_dir = "_site";
    content_dir = "content";
    template_dir = "templates";
    static_dir = "static";
  }

(* File IO and path normalization are shared via Memoir_lib. *)
let read_file = Memoir_lib.read_file
let normalize_path = Memoir_lib.normalize_path

(* Simple Dream server for development *)
let start_server () =
  let rss_handler _req =
    let pages = Memoir_lib.load_rss_pages ~content_dir:"content" in
    let rss_content = Memoir_lib.generate_rss_feed pages rss_config in
    Lwt.return
      (Dream.response
         ~headers:[ ("Content-Type", "application/rss+xml; charset=utf-8") ]
         rss_content)
  in

  let static_handler req =
    let uri = Dream.target req in
    (* Remove leading slash and normalize path *)
    let clean_path =
      if uri = "/" then "index" else String.sub uri 1 (String.length uri - 1)
    in
    let normalized_path = normalize_path clean_path in

    (* Try static subdirectory first, then direct path, then pages subdirectory *)
    let possible_paths =
      [
        Filename.concat static_subdir normalized_path;
        Filename.concat static_dir normalized_path;
        Filename.concat (Filename.concat static_dir "pages") normalized_path;
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
            (* Content type and cache policy, keyed together by extension *)
            let content_type, cache_control =
              match Filename.extension final_path with
              | ".html" ->
                  ("text/html; charset=utf-8", "no-cache, must-revalidate")
              | ".css" -> ("text/css", "public, max-age=604800")
              | ".js" -> ("application/javascript", "public, max-age=604800")
              | ".json" -> ("application/json", "public, max-age=86400")
              | ".png" -> ("image/png", "public, max-age=2592000")
              | ".jpg" | ".jpeg" -> ("image/jpeg", "public, max-age=2592000")
              | ".gif" -> ("image/gif", "public, max-age=2592000")
              | ".svg" -> ("image/svg+xml", "public, max-age=2592000")
              | ".ico" -> ("image/x-icon", "public, max-age=2592000")
              | ".woff" -> ("font/woff", "public, max-age=31536000, immutable")
              | ".woff2" -> ("font/woff2", "public, max-age=31536000, immutable")
              | ".ttf" -> ("font/ttf", "public, max-age=31536000, immutable")
              | ".eot" ->
                  ( "application/vnd.ms-fontobject",
                    "public, max-age=31536000, immutable" )
              | _ -> ("application/octet-stream", "public, max-age=86400")
            in
            try
              let content = read_file final_path in
              Lwt.return
                (Dream.response
                   ~headers:
                     [
                       ("Content-Type", content_type);
                       ("Cache-Control", cache_control);
                     ]
                   content)
            with _ ->
              Lwt.return (Dream.response ~code:500 "Internal Server Error")
          else try_paths rest
    in
    try_paths possible_paths
  in

  Dream.run ~port @@ Dream.logger
  @@ Dream.router
       [ Dream.get "/feed.xml" rss_handler; Dream.get "/**" static_handler ]

(* Entry point *)
let () =
  print_endline "Memoir Development Server - OCaml Static Site Generator";
  start_server ()
