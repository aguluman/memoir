(* Configuration *)
let port = 6060
let static_dir = "_site"
let static_subdir = Stdlib.Filename.concat static_dir "static"

(* Configuration for RSS feed generation *)
let rss_config =
  {
    Memoir_lib.site_title = "Chukwuma Akunyili's Website";
    site_description =
      "Thoughts on software engineering, functional programming, and technology";
    author = "Chukwuma Akunyili";
    base_url = "https://fearful-odds.rocks";
    output_dir = "_site";
    content_dir = "content";
    template_dir = "templates";
    static_dir = "static";
  }

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
  let parts = Str.split (Str.regexp_string Stdlib.Filename.dir_sep) path in
  let normalized = normalize [] parts |> List.rev in
  String.concat Stdlib.Filename.dir_sep normalized

(* Simple frontmatter parser for RSS feed *)
let parse_simple_frontmatter content =
  let lines = String.split_on_char '\n' content in
  let rec find_frontmatter acc in_frontmatter = function
    | [] -> ([], String.concat "\n" (List.rev acc))
    | "---" :: rest when not in_frontmatter -> find_frontmatter [] true rest
    | "---" :: rest when in_frontmatter ->
        (List.rev acc, String.concat "\n" rest)
    | line :: rest when in_frontmatter ->
        find_frontmatter (line :: acc) true rest
    | line :: rest -> find_frontmatter (line :: acc) false rest
  in
  find_frontmatter [] false lines

(* Extract title and date from frontmatter *)
let extract_metadata frontmatter_lines =
  let title = ref "Untitled" in
  let date = ref None in
  let description = ref None in
  List.iter
    (fun line ->
      if String.length line > 6 && String.sub line 0 6 = "title:" then
        let title_part = String.sub line 6 (String.length line - 6) in
        let clean_title = String.trim title_part in
        let final_title =
          if
            String.length clean_title > 2
            && clean_title.[0] = '"'
            && clean_title.[String.length clean_title - 1] = '"'
          then String.sub clean_title 1 (String.length clean_title - 2)
          else clean_title
        in
        title := final_title
      else if String.length line > 5 && String.sub line 0 5 = "date:" then
        let date_part = String.sub line 5 (String.length line - 5) in
        let clean_date = String.trim date_part in
        let final_date =
          if
            String.length clean_date > 2
            && clean_date.[0] = '"'
            && clean_date.[String.length clean_date - 1] = '"'
          then String.sub clean_date 1 (String.length clean_date - 2)
          else clean_date
        in
        date := Some final_date
      else if String.length line > 12 && String.sub line 0 12 = "description:"
      then
        let desc_part = String.sub line 12 (String.length line - 12) in
        let clean_desc = String.trim desc_part in
        let final_desc =
          if
            String.length clean_desc > 2
            && clean_desc.[0] = '"'
            && clean_desc.[String.length clean_desc - 1] = '"'
          then String.sub clean_desc 1 (String.length clean_desc - 2)
          else clean_desc
        in
        description := Some final_desc)
    frontmatter_lines;
  (!title, !date, !description)

(* Helper function to collect pages for RSS feed from actual content *)
let collect_dynamic_pages () =
  let content_base = "content/pages" in
  let blog_dir = Stdlib.Filename.concat content_base "blog" in
  let journal_dir = Stdlib.Filename.concat content_base "journal" in

  let load_pages_from_dir dir url_prefix =
    try
      if Sys.file_exists dir && Sys.is_directory dir then
        let files = Sys.readdir dir |> Array.to_list in
        List.filter_map
          (fun file ->
            if Stdlib.Filename.check_suffix file ".md" && file <> "index.md"
            then
              let file_path = Stdlib.Filename.concat dir file in
              try
                let content = read_file file_path in
                let frontmatter_lines, markdown_content =
                  parse_simple_frontmatter content
                in
                let title, date, description =
                  extract_metadata frontmatter_lines
                in
                let slug = Stdlib.Filename.remove_extension file in
                let url = "/" ^ url_prefix ^ "/" ^ slug in
                Some
                  {
                    Memoir_lib.metadata =
                      {
                        title;
                        date;
                        tags = [];
                        summary = description;
                        draft = false;
                      };
                    content = markdown_content;
                    url;
                    source_path = file_path;
                  }
              with _ -> None
            else None)
          files
      else []
    with _ -> []
  in

  let blog_pages = load_pages_from_dir blog_dir "blog" in
  let journal_pages = load_pages_from_dir journal_dir "journal" in

  let all_pages = blog_pages @ journal_pages in

  (* Sort by date (newest first) *)
  List.sort
    (fun a b ->
      match (a.Memoir_lib.metadata.date, b.Memoir_lib.metadata.date) with
      | Some date_a, Some date_b -> String.compare date_b date_a
      | Some _, None -> -1
      | None, Some _ -> 1
      | None, None -> 0)
    all_pages

(* Simple Dream server for development *)
let start_server () =
  let rss_handler _req =
    let pages = collect_dynamic_pages () in
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

    (* Try static subdirectory first, then try direct path, then try pages subdirectory *)
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
            let ext = Filename.extension final_path in
            let content_type =
              match ext with
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
            (* Add cache control headers for static assets *)
            let cache_control =
              match ext with
              (* Fonts: cache for 1 year (immutable) *)
              | ".woff" | ".woff2" | ".ttf" | ".eot" ->
                  "public, max-age=31536000, immutable"
              (* Images: cache for 1 month *)
              | ".png" | ".jpg" | ".jpeg" | ".gif" | ".svg" | ".ico" ->
                  "public, max-age=2592000"
              (* CSS/JS: cache for 1 week (can be updated more frequently) *)
              | ".css" | ".js" -> "public, max-age=604800"
              (* HTML: no cache (always fresh) *)
              | ".html" -> "no-cache, must-revalidate"
              | _ -> "public, max-age=86400"
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
