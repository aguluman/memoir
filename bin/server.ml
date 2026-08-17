module Routing = Memoir_content.Routing

let port = 6060
let config = Memoir_lib.default_config
let read_file = Memoir_lib.read_file

let start_server () =
  let rss_handler _req =
    let pages = Memoir_lib.load_rss_pages ~content_dir:config.content_dir in
    let rss_content = Memoir_lib.generate_rss_feed pages config in
    Lwt.return
      (Dream.response
         ~headers:[ ("Content-Type", "application/rss+xml; charset=utf-8") ]
         rss_content)
  in

  let static_handler req =
    match
      Routing.resolve_url ~site_root:config.output_dir (Dream.target req)
    with
    | None -> Lwt.return (Dream.response ~code:404 "Not Found")
    | Some final_path -> (
        let content_type, cache_control =
          match Filename.extension final_path with
          | ".html" -> ("text/html; charset=utf-8", "no-cache, must-revalidate")
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
        with exn ->
          Dream.error (fun log ->
              log "serving %s: %s" final_path (Printexc.to_string exn));
          Lwt.return (Dream.response ~code:500 "Internal Server Error"))
  in

  Dream.run ~port @@ Dream.logger
  @@ Dream.router
       [ Dream.get "/feed.xml" rss_handler; Dream.get "/**" static_handler ]

let () =
  print_endline "Memoir Development Server - OCaml Static Site Generator";
  start_server ()
