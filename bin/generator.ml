open Memoir_templates

(* Configuration type *)
type config_type = {
  author : string;
  output_dir : string;
  content_dir : string;
  template_dir : string;
  static_dir : string;
}

(* Configuration *)
let config =
  {
    author = "Chukwuma Akunyili";
    output_dir = "_site";
    content_dir = "content";
    template_dir = "templates";
    static_dir = "static";
  }

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

let write_output_file ~content ~path =
  let dir = Filename.dirname path in
  ensure_directory_exists dir;
  let file_type = determine_file_type path in
  let oc =
    match file_type with
    | Image -> open_out_bin path (* Binary mode for images *)
    | _ -> open_out path (* Text mode for other files *)
  in
  output_string oc content;
  close_out oc;
  Printf.printf "Written: %s\n" path

(* Process markdown content *)
let process_markdown ~file_path ~content =
  let open Memoir_content.Markdown_parser in
  let page = parse_markdown_file ~path:file_path ~content in
  match page.html_content with
  | Some html -> html
  | None -> ""

(* Route and URL mapping types *)
type route = {
  url_path : string;
  file_path : string;
  content_type : content_type;
}

and content_type =
  | Page
  | Post
  | Project
  | Journal
  | Asset

type route_metadata = {
  title : string option;
  (* Keeping these fields for future use *)
  _date : string option;
  _description : string option;
  _tags : string list;
}

let extract_route_metadata file_path =
  let content = read_file file_path in
  let frontmatter_pattern = "^---\n\\(\\(.\\|\n\\)*?\\)\n---\n" in
  let re = Str.regexp frontmatter_pattern in

  if Str.string_match re content 0 then
    let yaml_str = Str.matched_group 1 content in
    try
      (* Use your existing YAML parsing logic from markdown_parser.ml *)
      match Yaml.of_string yaml_str with
      | Error _ ->
          { title = None; _date = None; _description = None; _tags = [] }
      | Ok yaml ->
          let get_string yaml key =
            match Yaml.Util.find key yaml with
            | Ok (Some (`String s)) -> Some s
            | _ -> None
          in
          let get_string_list yaml key =
            match Yaml.Util.find key yaml with
            | Ok (Some (`A lst)) ->
                List.filter_map
                  (function
                    | `String s -> Some s
                    | _ -> None)
                  lst
            | _ -> []
          in
          {
            title = get_string yaml "title";
            _date = get_string yaml "date";
            _description = get_string yaml "description";
            _tags = get_string_list yaml "tags";
          }
    with _ -> { title = None; _date = None; _description = None; _tags = [] }
  else { title = None; _date = None; _description = None; _tags = [] }

(* Helper type for content entries *)
type content_entry = {
  title : string;
  date : string option;
  url : string;
  description : string option;
}

(* Common function to process markdown files in a directory *)
let process_content_files dir url_prefix =
  let entries = ref [] in
  (if Sys.file_exists dir && Sys.is_directory dir then
     let files = Sys.readdir dir in
     Array.iter
       (fun file ->
         let full_path = Filename.concat dir file in
         if
           (not (Sys.is_directory full_path))
           && Filename.extension file = ".md"
           && file <> "index.md"
         then
           let metadata = extract_route_metadata full_path in
           let entry : content_entry =
             {
               title =
                 (match metadata.title with
                 | Some t -> t
                 | None -> Filename.remove_extension file);
               date = metadata._date;
               description = metadata._description;
               url = url_prefix ^ Filename.remove_extension file;
             }
           in
           entries := entry :: !entries)
       files);

  (* Sort entries by date (newest first) *)
  List.sort
    (fun a b ->
      match (a.date, b.date) with
      | Some date_a, Some date_b -> String.compare date_b date_a
      | Some _, None -> -1
      | None, Some _ -> 1
      | None, None -> String.compare a.title b.title)
    !entries

(* Generate journal entry listings *)
let generate_journal_entries_html journal_dir =
  if not (Sys.file_exists journal_dir && Sys.is_directory journal_dir) then
    "<p><em>Journal directory not found.</em></p>"
  else
    let sorted_entries = process_content_files journal_dir "/journal/" in
    if List.length sorted_entries = 0 then
      "<p><em>No journal entries found.</em></p>"
    else
      let entries_html =
        List.map
          (fun entry ->
            let date_str =
              match entry.date with
              | Some d ->
                  Printf.sprintf "<span class=\"entry-date\">%s</span>" d
              | None -> ""
            in
            Printf.sprintf
              "<div class=\"journal-entry\">\n\
              \  <h3><a href=\"%s\">%s</a></h3>\n\
              \  %s\n\
               </div>\n"
              entry.url entry.title date_str)
          sorted_entries
      in
      "<div class=\"journal-entries\">\n"
      ^ String.concat "\n" entries_html
      ^ "\n</div>"

(* Generate blog entry listings *)
let generate_blog_entries_html blog_dir =
  if not (Sys.file_exists blog_dir && Sys.is_directory blog_dir) then
    "<p><em>Blog directory not found.</em></p>"
  else
    let sorted_entries = process_content_files blog_dir "/blog/" in
    if List.length sorted_entries = 0 then
      "<p><em>No blog posts found.</em></p>"
    else
      let entries_html =
        List.map
          (fun entry ->
            let date_str =
              match entry.date with
              | Some d ->
                  Printf.sprintf "<span class=\"blog-entry-date\">%s</span>" d
              | None -> ""
            in
            let description_str =
              match entry.description with
              | Some desc ->
                  Printf.sprintf "<p class=\"blog-entry-description\">%s</p>"
                    desc
              | None -> ""
            in
            Printf.sprintf
              "<article class=\"blog-entry\">\n\
              \  <h3><a href=\"%s\">%s</a></h3>\n\
              \  %s\n\
              \  %s\n\
               </article>\n"
              entry.url entry.title date_str description_str)
          sorted_entries
      in
      "<div class=\"blog-entries\">\n"
      ^ String.concat "\n" entries_html
      ^ "\n</div>"

(* URL path mapping *)
let clean_url_path path =
  let path = Filename.remove_extension path in
  (* Remove "content/pages/" or "pages/" prefix if it exists to create cleaner URLs *)
  let path =
    (* First remove content/ prefix *)
    let path =
      if Str.string_match (Str.regexp "content/\\(.*\\)") path 0 then
        Str.matched_group 1 path
      else path
    in
    (* Then remove pages/ prefix *)
    if Str.string_match (Str.regexp "pages/\\(.*\\)") path 0 then
      Str.matched_group 1 path
    else path
  in
  let path = if path = "index" then "/" else "/" ^ path in
  String.map
    (function
      | '\\' -> '/'
      | c -> c)
    path

(* Process Page Route *)
let process_route route =
  let output_path =
    match route.content_type with
    | Asset ->
        (* Static assets remain unchanged *)
        Filename.concat config.output_dir
          (String.sub route.url_path 1 (String.length route.url_path - 1))
    | _ ->
        if route.url_path = "/" then
          (* Root index page *)
          Filename.concat config.output_dir "index.html"
        else
          (* Get path without leading slash *)
          let clean_path =
            String.sub route.url_path 1 (String.length route.url_path - 1)
          in

          (* For paths like about/index or blog/index, we want to avoid creating duplicates *)
          if
            Filename.basename clean_path = "index"
            ||
            (* Also avoid duplicate index for files that would map to the same path *)
            String.contains clean_path '/'
            && String.ends_with ~suffix:"index/index" clean_path
          then
            (* For section index files like about/index.md *)
            let dir = Filename.dirname clean_path in
            Filename.concat config.output_dir (dir ^ "/index.html")
          else
            (* Normal files get /path/index.html *)
            Filename.concat config.output_dir (clean_path ^ "/index.html")
  in
  let metadata = extract_route_metadata route.file_path in
  let content = read_file route.file_path in
  match route.content_type with
  | Asset -> write_output_file ~content ~path:output_path
  | _ ->
      let title =
        match metadata.title with
        | Some t -> t
        | None -> Filename.remove_extension (Filename.basename route.file_path)
      in
      let html_content = process_markdown ~file_path:route.file_path ~content in

      (* Special handling for journal index page *)
      let final_html_content =
        if
          Filename.basename route.file_path = "index.md"
          && String.contains route.file_path '/'
          && String.contains (Filename.dirname route.file_path) '/'
          && Filename.basename (Filename.dirname route.file_path) = "journal"
        then
          (* This is the journal index page - inject journal entries *)
          let journal_dir = Filename.dirname route.file_path in
          let journal_entries_html =
            generate_journal_entries_html journal_dir
          in
          (* Replace the placeholder div with actual journal entries *)
          let pattern = "<div id=\"journal-entries-placeholder\"></div>" in
          let replacement = journal_entries_html in
          Str.global_replace
            (Str.regexp_string pattern)
            replacement html_content
        else if
          Filename.basename route.file_path = "index.md"
          && String.contains route.file_path '/'
          && String.contains (Filename.dirname route.file_path) '/'
          && Filename.basename (Filename.dirname route.file_path) = "blog"
        then
          (* This is the blog index page - inject blog entries *)
          let blog_dir = Filename.dirname route.file_path in
          let blog_entries_html = generate_blog_entries_html blog_dir in
          (* Replace the placeholder div with actual blog entries *)
          let pattern = "<div id=\"blog-entries-placeholder\"></div>" in
          let replacement = blog_entries_html in
          Str.global_replace
            (Str.regexp_string pattern)
            replacement html_content
        else html_content
      in
      let url_path =
        "/" ^ clean_url_path (Filename.remove_extension route.file_path)
      in
      let description =
        match metadata._description with
        | Some d -> d
        | None -> "A page from Chukwuma Akunyili's memoir"
      in
      let year = 2025 in
      let author = "Chukwuma Akunyili" in

      (* Add webring navigation to content *)
      let webring_html =
        {|<div class="webring-nav">
  <a href="https://ring.muhokama.fun/u/aguluman/pred" class="webring-link webring-prev prev" title="Previous site in the webring">← Pred</a>
  <p class="webring-description center">
    Hey, this site is part of 
    <a href="https://ring.muhokama.fun" target="_blank" rel="noopener noreferrer">ring.muhokama.fun!</a>
  </p>
  <a href="https://ring.muhokama.fun/u/aguluman/succ" class="webring-link webring-next next" title="Next site in the webring">Succ →</a>
</div>|}
      in
      let final_html_with_webring = final_html_content ^ "\n" ^ webring_html in

      (* Create proper page using template system *)
      let page_string =
        Templates.create_page ~current_path:url_path ~year ~author
          ~title_text:title ~description
          ~content:[ Tyxml.Html.Unsafe.data final_html_with_webring ]
          ~url:("https://fearful-odds.rocks" ^ url_path)
          ()
      in
      write_output_file ~content:page_string ~path:output_path

let content_type_of_path path =
  match Filename.dirname path with
  | "content/blog" | "content/pages/blog" -> Post
  | "content/projects" | "content/pages/projects" -> Project
  | "content/journal" | "content/pages/journal" -> Journal
  | "content/pages" | "content" -> Page
  | _ when Filename.extension path = "" -> Asset
  | _ -> Page

let collect_routes () =
  let routes = ref [] in
  let add_route ~url_path ~file_path ~content_type =
    routes := { url_path; file_path; content_type } :: !routes
  in
  let rec process_dir dir =
    if Sys.file_exists dir then
      Array.iter
        (fun entry ->
          let path = Filename.concat dir entry in
          if entry <> "." && entry <> ".." && entry <> "_site" then
            if Sys.is_directory path then process_dir path
            else
              let rel_path =
                let prefix_len = String.length config.content_dir + 1 in
                String.sub path prefix_len (String.length path - prefix_len)
              in
              let url_path = clean_url_path rel_path in
              let content_type = content_type_of_path path in
              add_route ~url_path ~file_path:path ~content_type)
        (Sys.readdir dir)
  in
  process_dir config.content_dir;
  List.rev !routes

(* Cache for incremental builds - using content hash for reliability *)
type build_cache = {
  file_hashes : (string * string) list; (* path, content_hash *)
  cache_file : string;
}

let load_build_cache () =
  let cache_file = Filename.concat config.output_dir ".build-cache" in
  try
    let content = read_file cache_file in
    let lines = String.split_on_char '\n' content in
    let file_hashes =
      List.filter_map
        (fun line ->
          match String.split_on_char '|' line with
          | [ path; hash ] -> Some (path, hash)
          | _ -> None (* Skip invalid or old format lines *))
        lines
    in
    { file_hashes; cache_file }
  with _ -> { file_hashes = []; cache_file }

let save_build_cache cache =
  let content =
    String.concat "\n"
      (List.map
         (fun (path, hash) -> Printf.sprintf "%s|%s" path hash)
         cache.file_hashes)
  in
  write_file cache.cache_file content

let hash_file path =
  let content = read_file path in
  Digest.to_hex (Digest.string content)

let is_index_page file_path =
  String.ends_with ~suffix:"/index.md" file_path
  && Str.string_match (Str.regexp ".*\\(blog\\|journal\\).*") file_path 0

let is_file_modified file_path cache =
  try
    (* Always rebuild blog/journal index pages since they aggregate other content *)
    if is_index_page file_path then true
    else
      let current_hash = hash_file file_path in
      match List.find_opt (fun (p, _) -> p = file_path) cache.file_hashes with
      | Some (_, last_hash) when last_hash <> "" ->
          (* Compare content hashes - immune to timestamp changes from fmt *)
          current_hash <> last_hash
      | _ -> true (* No cache entry or empty hash - treat as modified *)
  with _ -> true

let update_cache_entry file_path cache =
  try
    let current_hash = hash_file file_path in
    let file_hashes =
      (file_path, current_hash)
      :: List.filter (fun (p, _) -> p <> file_path) cache.file_hashes
    in
    { cache with file_hashes }
  with Unix.Unix_error _ -> cache

(* When processing journal/blog posts, invalidate their index pages *)
let update_cache_with_dependencies file_path cache =
  let updated_cache = update_cache_entry file_path cache in
  (* If this is a journal/blog post, mark the index as needing rebuild *)
  if
    Str.string_match (Str.regexp ".*/journal/.*") file_path 0
    && file_path <> "content/pages/journal/index.md"
  then
    (* Remove journal index from cache so it gets rebuilt *)
    let file_hashes =
      List.filter
        (fun (p, _) -> p <> "content/pages/journal/index.md")
        updated_cache.file_hashes
    in
    { updated_cache with file_hashes }
  else if
    Str.string_match (Str.regexp ".*/blog/.*") file_path 0
    && file_path <> "content/pages/blog/index.md"
  then
    (* Remove blog index from cache so it gets rebuilt *)
    let file_hashes =
      List.filter
        (fun (p, _) -> p <> "content/pages/blog/index.md")
        updated_cache.file_hashes
    in
    { updated_cache with file_hashes }
  else updated_cache

(* Extract RSS feed generation into a separate function *)
let generate_rss_feed () =
  let pages = ref [] in
  let blog_dir = Filename.concat config.content_dir "pages/blog" in
  let journal_dir = Filename.concat config.content_dir "pages/journal" in

  (* Process blog posts *)
  (if Sys.file_exists blog_dir && Sys.is_directory blog_dir then
     let files = Sys.readdir blog_dir in
     Array.iter
       (fun file ->
         let full_path = Filename.concat blog_dir file in
         if
           (not (Sys.is_directory full_path))
           && Filename.extension file = ".md"
           && file <> "index.md"
         then
           let metadata = extract_route_metadata full_path in
           let content = read_file full_path in
           let page =
             {
               Memoir_lib.metadata =
                 {
                   title =
                     (match metadata.title with
                     | Some t -> t
                     | None -> Filename.remove_extension file);
                   date = metadata._date;
                   tags = metadata._tags;
                   summary = metadata._description;
                   draft = false;
                 };
               content;
               url = "/blog/" ^ Filename.remove_extension file;
               source_path = full_path;
             }
           in
           pages := page :: !pages)
       files);

  (* Process journal entries *)
  (if Sys.file_exists journal_dir && Sys.is_directory journal_dir then
     let files = Sys.readdir journal_dir in
     Array.iter
       (fun file ->
         let full_path = Filename.concat journal_dir file in
         if
           (not (Sys.is_directory full_path))
           && Filename.extension file = ".md"
           && file <> "index.md"
         then
           let metadata = extract_route_metadata full_path in
           let content = read_file full_path in
           let page =
             {
               Memoir_lib.metadata =
                 {
                   title =
                     (match metadata.title with
                     | Some t -> t
                     | None -> Filename.remove_extension file);
                   date = metadata._date;
                   tags = metadata._tags;
                   summary = metadata._description;
                   draft = false;
                 };
               content;
               url = "/journal/" ^ Filename.remove_extension file;
               source_path = full_path;
             }
           in
           pages := page :: !pages)
       files);

  let rss_config =
    {
      Memoir_lib.site_title = "Chukwuma Akunyili's Blog";
      site_description =
        "Thoughts on software engineering, functional programming, and \
         technology";
      author = config.author;
      base_url = "https://fearful-odds.rocks";
      output_dir = config.output_dir;
      content_dir = config.content_dir;
      template_dir = config.template_dir;
      static_dir = config.static_dir;
    }
  in

  (* Sort pages by date (newest first) for RSS feed *)
  let sorted_pages =
    List.sort
      (fun a b ->
        match (a.Memoir_lib.metadata.date, b.Memoir_lib.metadata.date) with
        | Some date_a, Some date_b -> String.compare date_b date_a
        | Some _, None -> -1
        | None, Some _ -> 1
        | None, None -> 0)
      (List.rev !pages)
  in

  let rss_xml = Memoir_lib.generate_rss_feed sorted_pages rss_config in
  let rss_output_path = Filename.concat config.output_dir "feed.xml" in
  write_file rss_output_path rss_xml;
  Printf.printf "RSS feed generated at: %s (%d items)\n" rss_output_path
    (List.length sorted_pages)

(* Generate site *)
let generate_site () =
  print_endline "Starting site generation...";

  (* Load build cache *)
  let cache = load_build_cache () in

  (* Ensure output directory exists *)
  ensure_directory_exists config.output_dir;

  (* Remove duplicate index files if they exist *)
  let remove_duplicate_index_files () =
    let rec process_dir dir =
      if Sys.file_exists dir && Sys.is_directory dir then
        try
          let entries = Sys.readdir dir in
          Array.iter
            (fun entry ->
              if entry <> "." && entry <> ".." then
                let path = Filename.concat dir entry in
                if Sys.is_directory path then (
                  (* Check if we have both dir/index.html and dir/index/index.html *)
                  let index_path =
                    Filename.concat dir (entry ^ "/index.html")
                  in
                  let nested_index_path =
                    Filename.concat dir (entry ^ "/index/index.html")
                  in
                  if
                    Sys.file_exists index_path
                    && Sys.file_exists nested_index_path
                  then (
                    Printf.printf "Removing duplicate index file: %s\n"
                      nested_index_path;
                    Sys.remove nested_index_path;
                    (* Also try to remove the empty index directory *)
                    try
                      Unix.rmdir (Filename.concat dir (entry ^ "/index"));
                      Printf.printf "Removed empty directory: %s\n"
                        (Filename.concat dir (entry ^ "/index"))
                    with _ -> ());
                  process_dir path))
            entries
        with Sys_error _ -> ()
    in
    process_dir (Filename.concat config.output_dir "")
  in

  (* Collect and process routes *)
  let routes = collect_routes () in
  Printf.printf "Collected %d routes\n" (List.length routes);

  (* Process each route *)
  let final_cache =
    List.fold_left
      (fun acc (route : route) ->
        if is_file_modified route.file_path acc then (
          Printf.printf "Processing modified route: %s -> %s\n" route.file_path
            route.url_path;
          process_route route;
          update_cache_with_dependencies route.file_path acc)
        else (
          Printf.printf "Skipping unmodified route: %s\n" route.file_path;
          acc))
      cache routes
  in

  (* Remove any duplicate index files created during processing *)
  remove_duplicate_index_files ();

  (* Save updated cache *)
  save_build_cache final_cache;

  (* Generate RSS feed *)
  generate_rss_feed ();

  print_endline "Site generation complete!";
  ()

(* Entry point *)
let () =
  print_endline "Memoir Generation - OCaml Static Site Generator";
  try
    (* Check for --force flag in command line arguments *)
    let force_rebuild =
      Array.length Sys.argv > 1
      && (Sys.argv.(1) = "--force" || Sys.argv.(1) = "-f")
    in

    if force_rebuild then (
      print_endline "Forcing full rebuild (ignoring cache)...";

      (* Ensure output directory exists *)
      ensure_directory_exists config.output_dir;

      (* Collect routes *)
      let routes = collect_routes () in
      Printf.printf "Collected %d routes\n" (List.length routes);

      (* Process all routes *)
      List.iter
        (fun (route : route) ->
          Printf.printf "Processing route: %s -> %s\n" route.file_path
            route.url_path;
          process_route route)
        routes;

      (* Update cache *)
      let cache =
        {
          file_hashes = [];
          cache_file = Filename.concat config.output_dir ".build-cache";
        }
      in
      let final_cache =
        List.fold_left
          (fun acc (route : route) -> update_cache_entry route.file_path acc)
          cache routes
      in
      save_build_cache final_cache;

      (* Generate RSS feed - now just one call! *)
      generate_rss_feed ();

      print_endline "Forced rebuild complete!")
    else (
      print_endline "Using incremental build (cache enabled)...";
      generate_site ());

    exit 0
  with e ->
    prerr_endline ("Error: " ^ Printexc.to_string e);
    exit 1
