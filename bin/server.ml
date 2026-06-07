module Routing = Memoir_content.Routing

(* Configuration *)
let port = 6060

(* The one canonical configuration lives in Memoir_lib (shared with the
   generator); the server serves the site it wrote to [output_dir]. *)
let config = Memoir_lib.default_config

(* File IO is shared via Memoir_lib. *)
let read_file = Memoir_lib.read_file

(* Simple Dream server for development *)
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
    (* Path resolution lives in Routing (the single home for the URL scheme);
       the server only adds serve-time policy: content type and caching. *)
    match
      Routing.resolve_url ~site_root:config.output_dir (Dream.target req)
    with
    | None -> Lwt.return (Dream.response ~code:404 "Not Found")
    | Some final_path -> (
        (* Content type and cache policy, keyed together by extension *)
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
          (* Surface the cause (Leroy) — Dream.logger records the request and
              500 status, but not *why* it failed. *)
          Dream.error (fun log ->
              log "serving %s: %s" final_path (Printexc.to_string exn));
          Lwt.return (Dream.response ~code:500 "Internal Server Error"))
  in

  Dream.run ~port @@ Dream.logger
  @@ Dream.router
       [ Dream.get "/feed.xml" rss_handler; Dream.get "/**" static_handler ]

(* Entry point *)
let () =
  print_endline "Memoir Development Server - OCaml Static Site Generator";
  start_server ()
