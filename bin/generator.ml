open Memoir_templates
module Markdown_parser = Memoir_content.Markdown_parser
module Routing = Memoir_content.Routing
module Content_loader = Memoir_content.Content_loader
module Build_cache = Memoir_content.Build_cache

(* The one canonical configuration lives in Memoir_lib (single source of truth,
   shared with the dev server). *)
let config = Memoir_lib.default_config

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
                    display_config.date_class
                    (Content_types.Date.to_iso_string d)
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
      let fm_opt = Markdown_parser.frontmatter_of_content content in
      let fm = Option.value fm_opt ~default:Content_types.empty_frontmatter in
      let title =
        (* No frontmatter block, or a keyless "Untitled" block, falls back to
           the filename. *)
        match fm_opt with
        | Some f when f.Content_types.title <> "Untitled" ->
            f.Content_types.title
        | _ -> Filename.remove_extension (Filename.basename route.file_path)
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
      let author =
        match fm.Content_types.author with
        | Some a -> a
        | None -> config.author
      in
      let image = fm.Content_types.featured_image in
      let modified =
        Option.map Content_types.Date.to_iso_string fm.Content_types.updated
      in
      let page_class = Option.value fm.Content_types.layout ~default:"page" in

      (* Create the page via the template system. Frontmatter now drives the
         byline (author), the Open Graph image (featured_image), the article
         modified-time (updated) and the body layout class (layout); the webring
         navigation is appended inside Templates.create_page. *)
      let page_string =
        Templates.create_page ~current_path:url_path ~year ~author ~page_class
          ?image ?modified ~title_text:title ~description
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

(* Path of the on-disk incremental-build cache; the cache logic itself lives in
   Memoir_content.Build_cache. *)
let cache_file_path = Filename.concat config.output_dir ".build-cache"

(* Extract RSS feed generation into a separate function *)
let generate_rss_feed () =
  let pages = Memoir_lib.load_rss_pages ~content_dir:config.content_dir in
  let rss_xml = Memoir_lib.generate_rss_feed pages config in
  let rss_output_path = Filename.concat config.output_dir "feed.xml" in
  write_file rss_output_path rss_xml;
  Printf.printf "RSS feed generated at: %s (%d items)\n" rss_output_path
    (List.length pages)

(* Generate site. With ~force:true, the cache is ignored and every route is
   rebuilt; the cache is still rewritten afterwards. *)
let generate_site ?(force = false) () =
  if force then print_endline "Forcing full rebuild (ignoring cache)..."
  else print_endline "Starting site generation...";

  (* Load (or reset) the build cache *)
  let cache =
    if force then Build_cache.empty ~cache_file:cache_file_path
    else Build_cache.load ~cache_file:cache_file_path
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
        if force || Build_cache.needs_rebuild acc route.file_path then (
          Printf.printf "Processing route: %s -> %s\n" route.file_path
            route.url_path;
          process_route route;
          Build_cache.record acc route.file_path)
        else (
          Printf.printf "Skipping unmodified route: %s\n" route.file_path;
          acc))
      cache routes
  in

  (* Save updated cache *)
  Build_cache.save final_cache;

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
