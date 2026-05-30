open Memoir_templates
module Markdown_parser = Memoir_content.Markdown_parser
module Routing = Memoir_content.Routing
module Content_loader = Memoir_content.Content_loader

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

(* File IO and path utilities are shared via Memoir_lib (lib/memoir_lib.ml). *)
let read_file = Memoir_lib.read_file
let write_file = Memoir_lib.write_file
let ensure_directory_exists = Memoir_lib.ensure_directory_exists

(* Process markdown content into HTML *)
let process_markdown ~file_path ~content =
  let page = Markdown_parser.parse_markdown_file ~path:file_path ~content in
  match page.Content_types.html_content with
  | Some html -> html
  | None -> ""

(* Route and URL mapping types *)
type route = {
  url_path : string;
  file_path : string;
  content_type : Content_types.content_type;
}

(* Configuration for rendering different content listings *)
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

(* Generic function to generate entry listings. The listing data comes from
   Content_loader; this function only renders it. *)
let generate_entries_html dir display_config =
  if not (Sys.file_exists dir && Sys.is_directory dir) then
    Printf.sprintf "<p><em>%s</em></p>" display_config.not_found_message
  else
    let entries =
      Content_loader.list_entries ~dir ~url_prefix:display_config.url_prefix
    in
    if entries = [] then
      Printf.sprintf "<p><em>%s</em></p>" display_config.empty_message
    else
      let entries_html =
        List.map
          (fun (entry : Content_loader.entry) ->
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
          entries
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

(* True when file_path is the index.md of the given section directory. *)
let is_section_index file_path section =
  Filename.basename file_path = "index.md"
  && Filename.basename (Filename.dirname file_path) = section

let replace_placeholder pat rep s =
  Str.global_replace (Str.regexp_string pat) rep s

(* Process Page Route *)
let process_route route =
  match route.content_type with
  | Content_types.Asset ->
      (* Static assets remain unchanged *)
      let clean =
        if String.length route.url_path > 0 && route.url_path.[0] = '/' then
          String.sub route.url_path 1 (String.length route.url_path - 1)
        else route.url_path
      in
      write_file
        (Filename.concat config.output_dir clean)
        (read_file route.file_path)
  | _ ->
      let output_path =
        Routing.path_to_output_path route.file_path
          ~output_dir:config.output_dir
      in
      let content = read_file route.file_path in
      let fm = Markdown_parser.frontmatter_of_content content in
      let title =
        (* Fall back to the filename when frontmatter has no usable title. *)
        match fm.Content_types.title with
        | "" | "Untitled" ->
            Filename.remove_extension (Filename.basename route.file_path)
        | t -> t
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
      let url_path = Routing.path_to_url_path route.file_path in
      let description =
        match fm.Content_types.description with
        | Some d -> d
        | None -> "A page from Chukwuma Akunyili's memoir"
      in
      let year = Unix.(localtime (time ())).tm_year + 1900 in
      let author = "Chukwuma Akunyili" in

      (* Create proper page using template system. The webring navigation is now
         appended inside Templates.create_page. *)
      let page_string =
        Templates.create_page ~current_path:url_path ~year ~author
          ~title_text:title ~description
          ~content:[ Tyxml.Html.Unsafe.data final_html_content ]
          ~url:(Memoir_lib.site_domain ^ url_path)
          ()
      in
      write_file output_path page_string

(* Collect every content file into a route, classifying and URL-mapping each
   via the shared Routing module. *)
let collect_routes () =
  Content_loader.walk_files config.content_dir
  |> List.map (fun file_path ->
      {
        file_path;
        url_path = Routing.path_to_url_path file_path;
        content_type = Routing.classify file_path;
      })

(* Section index page that aggregates a given post's section, if any. *)
let index_path_for = function
  | Content_types.Post -> Some "content/pages/blog/index.md"
  | Content_types.Journal -> Some "content/pages/journal/index.md"
  | _ -> None

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

(* Blog/journal index pages aggregate other content, so always rebuild them. *)
let is_index_page file_path =
  String.ends_with ~suffix:"/index.md" file_path
  &&
  match Routing.classify file_path with
  | Content_types.Post | Content_types.Journal -> true
  | _ -> false

let is_file_modified file_path cache =
  try
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

(* When processing journal/blog posts, invalidate their index pages so the
   aggregated listings are regenerated. *)
let update_cache_with_dependencies file_path cache =
  let updated_cache = update_cache_entry file_path cache in
  match index_path_for (Routing.classify file_path) with
  | Some index_path when file_path <> index_path ->
      let file_hashes =
        List.filter (fun (p, _) -> p <> index_path) updated_cache.file_hashes
      in
      { updated_cache with file_hashes }
  | _ -> updated_cache

(* Extract RSS feed generation into a separate function *)
let generate_rss_feed () =
  let pages = Memoir_lib.load_rss_pages ~content_dir:config.content_dir in
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
  let rss_xml = Memoir_lib.generate_rss_feed pages rss_config in
  let rss_output_path = Filename.concat config.output_dir "feed.xml" in
  write_file rss_output_path rss_xml;
  Printf.printf "RSS feed generated at: %s (%d items)\n" rss_output_path
    (List.length pages)

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
