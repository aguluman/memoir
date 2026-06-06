(** Integration tests.

    These drive the consolidated library pipeline (the same functions
    [bin/generator.ml] and [bin/server.ml] now call) against a temporary on-disk
    content fixture, and assert the emitted output — files, listings, RSS, and a
    fully-assembled HTML page. They exercise the temp-dir scaffolding in
    {!Test_helpers}. *)

module Markdown_parser = Memoir_content.Markdown_parser
module Routing = Memoir_content.Routing
module Content_loader = Memoir_content.Content_loader
module Templates = Memoir_templates.Templates

(* A blog/journal post fixture with frontmatter. *)
let post ~title ~date ~body =
  Printf.sprintf "---\ntitle: %s\ndate: %s\ndescription: %s\n---\n\n%s\n" title
    date (title ^ " summary") body

let rss_config =
  {
    Memoir_lib.site_title = "Test Blog";
    site_description = "A test feed";
    author = "Tester";
    base_url = Memoir_lib.site_domain;
    output_dir = "_site";
    content_dir = "content";
  }

(* Enumeration: walk_files finds content files and skips the _site dir. *)
let test_walk_files () =
  Test_helpers.with_temp_dir (fun root ->
      let cdir = Filename.concat root "content" in
      Memoir_lib.write_file (Filename.concat cdir "pages/index.md") "# Home";
      Memoir_lib.write_file (Filename.concat cdir "pages/blog/p.md") "# P";
      Memoir_lib.write_file (Filename.concat cdir "_site/old.html") "stale";
      let bases =
        Content_loader.walk_files cdir |> List.map Filename.basename
      in
      Alcotest.(check bool) "finds home page" true (List.mem "index.md" bases);
      Alcotest.(check bool) "finds blog post" true (List.mem "p.md" bases);
      Alcotest.(check bool)
        "skips generated _site" true
        (not (List.mem "old.html" bases)))

(* Listing: section entries are built from frontmatter, sorted newest-first,
   with index.md excluded and slug-based URLs. *)
let test_listing_entries () =
  Test_helpers.with_temp_dir (fun root ->
      let blog = Filename.concat root "content/pages/blog" in
      Memoir_lib.write_file
        (Filename.concat blog "first-post.md")
        (post ~title:"First Post" ~date:"2025-01-01" ~body:"x");
      Memoir_lib.write_file
        (Filename.concat blog "second-post.md")
        (post ~title:"Second Post" ~date:"2025-06-01" ~body:"y");
      Memoir_lib.write_file
        (Filename.concat blog "index.md")
        "---\ntitle: Blog\n---\n";
      let entries =
        Content_loader.list_entries ~dir:blog ~url_prefix:"/blog/"
      in
      Alcotest.(check int)
        "two entries (index.md excluded)" 2 (List.length entries);
      let first = List.hd entries in
      Alcotest.(check string)
        "newest first" "Second Post" first.Content_loader.title;
      Alcotest.(check string)
        "url uses slug" "/blog/second-post" first.Content_loader.url)

(* RSS: the shared loader + feed generator produce a feed from the fixture. *)
let test_rss_feed () =
  Test_helpers.with_temp_dir (fun root ->
      let cdir = Filename.concat root "content" in
      Memoir_lib.write_file
        (Filename.concat cdir "pages/blog/first-post.md")
        (post ~title:"First Post" ~date:"2025-01-01"
           ~body:"Hello from the first post.");
      Memoir_lib.write_file
        (Filename.concat cdir "pages/blog/second-post.md")
        (post ~title:"Second Post" ~date:"2025-06-01"
           ~body:"Hello from the second post.");
      Memoir_lib.write_file
        (Filename.concat cdir "pages/blog/index.md")
        "---\ntitle: Blog\n---\n\n# Blog\n";
      let pages = Memoir_lib.load_rss_pages ~content_dir:cdir in
      Alcotest.(check int) "two posts (index.md excluded)" 2 (List.length pages);
      let xml = Memoir_lib.generate_rss_feed pages rss_config in
      Alcotest.(check bool)
        "is an rss document" true
        (Test_helpers.contains xml "<rss");
      Alcotest.(check bool)
        "has first post title" true
        (Test_helpers.contains xml "First Post");
      Alcotest.(check bool)
        "has second post title" true
        (Test_helpers.contains xml "Second Post");
      Alcotest.(check bool)
        "links to a post" true
        (Test_helpers.contains xml
           (Memoir_lib.site_domain ^ "/blog/first-post")))

(* Full page: parse a fixture, assemble it with create_page, write it to disk
   via the shared writer, and verify the emitted file and its contents. *)
let test_page_written_to_disk () =
  Test_helpers.with_temp_dir (fun root ->
      let cdir = Filename.concat root "content" in
      let logical = "content/pages/about/index.md" in
      let md =
        "---\n\
         title: About Me\n\
         description: Who I am\n\
         ---\n\n\
         # About\n\n\
         Hello **world**.\n"
      in
      Memoir_lib.write_file (Filename.concat cdir "pages/about/index.md") md;
      (* Read the fixture back through the system's own reader. *)
      let content =
        Memoir_lib.read_file (Filename.concat cdir "pages/about/index.md")
      in
      let page_data =
        Markdown_parser.parse_markdown_file ~path:logical ~content
      in
      let body_html =
        match page_data.Content_types.html_content with
        | Some h -> h
        | None -> ""
      in
      let fm = page_data.Content_types.frontmatter in
      let title =
        match fm.Content_types.title with
        | "" | "Untitled" -> "about"
        | t -> t
      in
      let url = Routing.path_to_url_path logical in
      let out_dir = Filename.concat root "_site" in
      let out = Routing.path_to_output_path logical ~output_dir:out_dir in
      let html =
        Templates.create_page ~current_path:url ~year:2026 ~author:"Tester"
          ~title_text:title
          ~description:
            (match fm.Content_types.description with
            | Some d -> d
            | None -> "")
          ~content:[ Tyxml.Html.Unsafe.data body_html ]
          ~url:(Memoir_lib.site_domain ^ url)
          ()
      in
      Memoir_lib.write_file out html;
      Test_helpers.assert_file_exists out;
      Alcotest.(check string)
        "canonical output path"
        (Filename.concat out_dir "about/index.html")
        out;
      let written = Memoir_lib.read_file out in
      Alcotest.(check bool)
        "title present" true
        (Test_helpers.contains written "About Me");
      Alcotest.(check bool)
        "rendered body present" true
        (Test_helpers.contains written "Hello");
      Alcotest.(check bool)
        "markdown converted to html" true
        (Test_helpers.contains written "<strong>"
        && Test_helpers.contains written "world");
      Alcotest.(check bool)
        "canonical link present" true
        (Test_helpers.contains written "rel=\"canonical\"");
      Alcotest.(check bool)
        "canonical url present" true
        (Test_helpers.contains written (Memoir_lib.site_domain ^ "/about"));
      Alcotest.(check bool)
        "webring present" true
        (Test_helpers.contains written "webring-nav"))

let () =
  Alcotest.run "Integration Tests"
    [
      ( "Generation pipeline",
        [
          Alcotest.test_case "Walk content files" `Quick test_walk_files;
          Alcotest.test_case "Section listing entries" `Quick
            test_listing_entries;
          Alcotest.test_case "RSS feed from fixture" `Quick test_rss_feed;
          Alcotest.test_case "Page written to disk" `Quick
            test_page_written_to_disk;
        ] );
    ]
