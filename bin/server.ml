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

(* Read a file's contents (binary; closes even on exception) *)
let read_file path = In_channel.with_open_bin path In_channel.input_all

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

(* Extract title/date/description from frontmatter lines *)
let extract_metadata frontmatter_lines =
  (* Trim and strip surrounding double quotes *)
  let unquote s =
    let s = String.trim s in
    let n = String.length s in
    if n > 2 && s.[0] = '"' && s.[n - 1] = '"' then String.sub s 1 (n - 2)
    else s
  in
  (* Value following "key:" if the line carries one, else None *)
  let field key line =
    let klen = String.length key in
    if String.length line > klen && String.starts_with ~prefix:key line then
      Some (unquote (String.sub line klen (String.length line - klen)))
    else None
  in
  let title = ref "Untitled" and date = ref None and description = ref None in
  List.iter
    (fun line ->
      let set key assign =
        match field key line with
        | Some v -> assign v
        | None -> ()
      in
      set "title:" (fun v -> title := v);
      set "date:" (fun v -> date := Some v);
      set "description:" (fun v -> description := Some v))
    frontmatter_lines;
  (!title, !date, !description)

(* Newest-first date ordering (None sorts last) *)
let compare_by_date_desc a b =
  match (a, b) with
  | Some x, Some y -> String.compare y x
  | Some _, None -> -1
  | None, Some _ -> 1
  | None, None -> 0

(* Collect pages for the RSS feed from actual content *)
let collect_dynamic_pages () =
  let content_base = "content/pages" in
  let blog_dir = Filename.concat content_base "blog" in
  let journal_dir = Filename.concat content_base "journal" in

  let load_pages_from_dir dir url_prefix =
    try
      if Sys.file_exists dir && Sys.is_directory dir then
        Sys.readdir dir |> Array.to_list
        |> List.filter_map (fun file ->
            if Filename.check_suffix file ".md" && file <> "index.md" then
              let file_path = Filename.concat dir file in
              try
                let content = read_file file_path in
                let frontmatter_lines, markdown_content =
                  parse_simple_frontmatter content
                in
                let title, date, description =
                  extract_metadata frontmatter_lines
                in
                let slug = Filename.remove_extension file in
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
                    url = "/" ^ url_prefix ^ "/" ^ slug;
                    source_path = file_path;
                  }
              with _ -> None
            else None)
      else []
    with _ -> []
  in

  let blog_pages = load_pages_from_dir blog_dir "blog" in
  let journal_pages = load_pages_from_dir journal_dir "journal" in
  let all_pages = blog_pages @ journal_pages in

  (* Sort by date (newest first) *)
  List.sort
    (fun a b ->
      compare_by_date_desc a.Memoir_lib.metadata.date b.Memoir_lib.metadata.date)
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
