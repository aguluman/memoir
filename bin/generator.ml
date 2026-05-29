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

(* Binary-safe read: with_open_bin closes the channel even on exception, and
   binary mode avoids CRLF translation that corrupts images / shifts byte
   counts on Windows. *)
let read_file path =
  let path = normalize_path path in
  try In_channel.with_open_bin path In_channel.input_all
  with Sys_error msg ->
    failwith (Printf.sprintf "Failed to read file %s: %s" path msg)

(* Binary-safe write, used for every output (HTML, CSS, JS, images alike). *)
let write_file path content =
  let path = normalize_path path in
  ensure_directory_exists (Filename.dirname path);
  Printf.printf "Writing file: %s\n" path;
  try
    Out_channel.with_open_bin path (fun oc ->
        Out_channel.output_string oc content)
  with Sys_error msg ->
    failwith (Printf.sprintf "Failed to write file %s: %s" path msg)

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

(* Separate type for classifying content sections (for index invalidation) *)
type content_section =
  | Blog
  | Journal
  | Other

(* Metadata type for route extraction *)
type route_metadata = {
  title : string option;
  (* Keeping these fields for future use *)
  _date : string option;
  _description : string option;
  _tags : string list;
}

let empty_route_metadata =
  { title = None; _date = None; _description = None; _tags = [] }

let extract_route_metadata file_path =
  let content = read_file file_path in
  let frontmatter_pattern = "^---\n\\(\\(.\\|\n\\)*?\\)\n---\n" in
  let re = Str.regexp frontmatter_pattern in

  if Str.string_match re content 0 then
    let yaml_str = Str.matched_group 1 content in
    try
      (* Use your existing YAML parsing logic from markdown_parser.ml *)
      match Yaml.of_string yaml_str with
      | Error _ -> empty_route_metadata
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
    with _ -> empty_route_metadata
  else empty_route_metadata

(* Helper type for content entries *)
type content_entry = {
  title : string;
  date : string option;
  url : string;
  description : string option;
}

(* Configuration for rendering different content types *)
type entry_display_config = {
  url_prefix : string;
  entry_element : string; (* "article", "div", etc. *)
  entry_class : string; (* "blog-entry", "journal-entry", etc. *)
  container_class : string; (* "blog-entries", "journal-entries", etc. *)
  date_class : string;
  show_description : bool;
  empty_message : string;
  not_found_message : string;
}

(* List the renderable markdown files in a directory (skips index.md and
   subdirectories). Shared by content listing and RSS collection. *)
let markdown_files dir =
  if Sys.file_exists dir && Sys.is_directory dir then
    Sys.readdir dir |> Array.to_list
    |> List.filter (fun f ->
        Filename.extension f = ".md"
        && f <> "index.md"
        && not (Sys.is_directory (Filename.concat dir f)))
    |> List.map (Filename.concat dir)
  else []

(* Newest-first date ordering (None sorts last). *)
let compare_by_date_desc date_a date_b =
  match (date_a, date_b) with
  | Some a, Some b -> String.compare b a
  | Some _, None -> -1
  | None, Some _ -> 1
  | None, None -> 0

(* Common function to process markdown files in a directory *)
let process_content_files dir url_prefix =
  let entries =
    List.map
      (fun full_path ->
        let file = Filename.basename full_path in
        let metadata = extract_route_metadata full_path in
        {
          title =
            (match metadata.title with
            | Some t -> t
            | None -> Filename.remove_extension file);
          date = metadata._date;
          description = metadata._description;
          url = url_prefix ^ Filename.remove_extension file;
        })
      (markdown_files dir)
  in
  (* Sort entries by date (newest first), falling back to title when both
     entries are undated. *)
  List.sort
    (fun a b ->
      match (a.date, b.date) with
      | None, None -> String.compare a.title b.title
      | _ -> compare_by_date_desc a.date b.date)
    entries

(* Generic function to generate entry listings *)
let generate_entries_html dir display_config =
  if not (Sys.file_exists dir && Sys.is_directory dir) then
    Printf.sprintf "<p><em>%s</em></p>" display_config.not_found_message
  else
    let sorted_entries = process_content_files dir display_config.url_prefix in
    if List.length sorted_entries = 0 then
      Printf.sprintf "<p><em>%s</em></p>" display_config.empty_message
    else
      let entries_html =
        List.map
          (fun entry ->
            let date_str =
              match entry.date with
              | Some d ->
                  Printf.sprintf "<span class=\"%s\">%s</span>"
                    display_config.date_class d
              | None -> ""
            in
            let description_str =
              if display_config.show_description then
                match entry.description with
                | Some desc ->
                    Printf.sprintf "<p class=\"%s-description\">%s</p>"
                      display_config.entry_class desc
                | None -> ""
              else ""
            in
            Printf.sprintf
              "<%s class=\"%s\">\n\
              \  <h3><a href=\"%s\">%s</a></h3>\n\
              \  %s\n\
              \  %s\n\
               </%s>\n"
              display_config.entry_element display_config.entry_class entry.url
              entry.title date_str description_str display_config.entry_element)
          sorted_entries
      in
      Printf.sprintf "<div class=\"%s\">\n%s\n</div>"
        display_config.container_class
        (String.concat "\n" entries_html)

(* Generate journal entry listings *)
let generate_journal_entries_html journal_dir =
  let config =
    {
      url_prefix = "/journal/";
      entry_element = "div";
      entry_class = "journal-entry";
      container_class = "journal-entries";
      date_class = "entry-date";
      show_description = false;
      empty_message = "No journal entries found.";
      not_found_message = "Journal directory not found.";
    }
  in
  generate_entries_html journal_dir config

(* Generate blog entry listings *)
let generate_blog_entries_html blog_dir =
  let config =
    {
      url_prefix = "/blog/";
      entry_element = "article";
      entry_class = "blog-entry";
      container_class = "blog-entries";
      date_class = "blog-entry-date";
      show_description = true;
      empty_message = "No blog posts found.";
      not_found_message = "Blog directory not found.";
    }
  in
  generate_entries_html blog_dir config

(* Strip a leading "<prefix>/" group from a path if present. *)
let strip_prefix re s =
  if Str.string_match (Str.regexp re) s 0 then Str.matched_group 1 s else s

(* URL path mapping *)
let clean_url_path path =
  (* Drop content/ then pages/ prefixes for cleaner URLs. *)
  let path =
    Filename.remove_extension path
    |> strip_prefix "content/\\(.*\\)"
    |> strip_prefix "pages/\\(.*\\)"
  in
  let path = if path = "index" then "/" else "/" ^ path in
  String.map
    (function
      | '\\' -> '/'
      | c -> c)
    path

(* True when file_path is the index.md of the given section directory. *)
let is_section_index file_path section =
  Filename.basename file_path = "index.md"
  && Filename.basename (Filename.dirname file_path) = section

let replace_placeholder pat rep s =
  Str.global_replace (Str.regexp_string pat) rep s

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
            String.ends_with ~suffix:"index/index" clean_path
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
  | Asset -> write_file output_path content
  | _ ->
      let title =
        match metadata.title with
        | Some t -> t
        | None -> Filename.remove_extension (Filename.basename route.file_path)
      in
      let html_content = process_markdown ~file_path:route.file_path ~content in

      (* Inject blog/journal listings into their section index pages. *)
      let final_html_content =
        let dir = Filename.dirname route.file_path in
        if is_section_index route.file_path "journal" then
          replace_placeholder "<div id=\"journal-entries-placeholder\"></div>"
            (generate_journal_entries_html dir)
            html_content
        else if is_section_index route.file_path "blog" then
          replace_placeholder "<div id=\"blog-entries-placeholder\"></div>"
            (generate_blog_entries_html dir)
            html_content
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
      let year = Unix.(localtime (time ())).tm_year + 1900 in
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
          ~url:(Memoir_lib.site_domain ^ url_path)
          ()
      in
      write_file output_path page_string

let content_type_of_path path =
  match Filename.dirname path with
  | "content/blog" | "content/pages/blog" -> Post
  | "content/projects" | "content/pages/projects" -> Project
  | "content/journal" | "content/pages/journal" -> Journal
  | "content/pages" | "content" -> Page
  | _ when Filename.extension path = "" -> Asset
  | _ -> Page

let classify_content_path file_path =
  if Str.string_match (Str.regexp ".*/blog/.*") file_path 0 then Blog
  else if Str.string_match (Str.regexp ".*/journal/.*") file_path 0 then Journal
  else Other

let get_index_path_for_section = function
  | Blog -> Some "content/pages/blog/index.md"
  | Journal -> Some "content/pages/journal/index.md"
  | Other -> None

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

let cache_file_path = Filename.concat config.output_dir ".build-cache"

let load_build_cache () =
  try
    let content = read_file cache_file_path in
    let lines = String.split_on_char '\n' content in
    let file_hashes =
      List.filter_map
        (fun line ->
          match String.split_on_char '|' line with
          | [ path; hash ] -> Some (path, hash)
          | _ -> None (* Skip invalid or old format lines *))
        lines
    in
    { file_hashes; cache_file = cache_file_path }
  with _ -> { file_hashes = []; cache_file = cache_file_path }

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
  &&
  match classify_content_path file_path with
  | Blog | Journal -> true
  | Other -> false

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

  match classify_content_path file_path with
  | (Blog | Journal) as section -> (
      match get_index_path_for_section section with
      | Some index_path when file_path <> index_path ->
          let file_hashes =
            List.filter
              (fun (p, _) -> p <> index_path)
              updated_cache.file_hashes
          in
          { updated_cache with file_hashes }
      | _ -> updated_cache)
  | Other -> updated_cache

(* Generic function to collect content from a directory for RSS feed *)
let collect_content_from_dir dir url_prefix =
  List.map
    (fun full_path ->
      let file = Filename.basename full_path in
      let metadata = extract_route_metadata full_path in
      let content = read_file full_path in
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
        url = url_prefix ^ Filename.remove_extension file;
        source_path = full_path;
      })
    (markdown_files dir)

(* Extract RSS feed generation into a separate function *)
let generate_rss_feed () =
  let blog_dir = Filename.concat config.content_dir "pages/blog" in
  let journal_dir = Filename.concat config.content_dir "pages/journal" in

  (* Collect content from both directories *)
  let blog_pages = collect_content_from_dir blog_dir "/blog/" in
  let journal_pages = collect_content_from_dir journal_dir "/journal/" in
  let pages = blog_pages @ journal_pages in

  let rss_config =
    {
      Memoir_lib.site_title = "Chukwuma Akunyili's Blog";
      site_description =
        "Thoughts on software engineering, functional programming, and \
         technology";
      author = config.author;
      base_url = Memoir_lib.site_domain;
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
        compare_by_date_desc a.Memoir_lib.metadata.date
          b.Memoir_lib.metadata.date)
      pages
  in

  let rss_xml = Memoir_lib.generate_rss_feed sorted_pages rss_config in
  let rss_output_path = Filename.concat config.output_dir "feed.xml" in
  write_file rss_output_path rss_xml;
  Printf.printf "RSS feed generated at: %s (%d items)\n" rss_output_path
    (List.length sorted_pages)

(* Remove duplicate index files (dir/index.html alongside dir/index/index.html) *)
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
                let index_path = Filename.concat dir (entry ^ "/index.html") in
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

(* Generate site. With ~force:true, the cache is ignored and every route is
   rebuilt; the cache is still rewritten afterwards. *)
let generate_site ?(force = false) () =
  if force then print_endline "Forcing full rebuild (ignoring cache)..."
  else print_endline "Starting site generation...";

  (* Load (or reset) the build cache *)
  let cache =
    if force then { file_hashes = []; cache_file = cache_file_path }
    else load_build_cache ()
  in

  (* Ensure output directory exists *)
  ensure_directory_exists config.output_dir;

  (* Collect and process routes *)
  let routes = collect_routes () in
  Printf.printf "Collected %d routes\n" (List.length routes);

  (* Process each route, skipping unmodified ones unless forcing *)
  let final_cache =
    List.fold_left
      (fun acc (route : route) ->
        if force || is_file_modified route.file_path acc then (
          Printf.printf "Processing route: %s -> %s\n" route.file_path
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

  print_endline "Site generation complete!"

(* Entry point *)
let () =
  print_endline "Memoir Generation - OCaml Static Site Generator";
  try
    (* Check for --force flag in command line arguments *)
    let force =
      Array.length Sys.argv > 1
      && (Sys.argv.(1) = "--force" || Sys.argv.(1) = "-f")
    in
    if not force then print_endline "Using incremental build (cache enabled)...";
    generate_site ~force ();
    exit 0
  with e ->
    prerr_endline ("Error: " ^ Printexc.to_string e);
    exit 1
