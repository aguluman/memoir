open Alcotest
open Test_helpers
open Content_types
open Memoir_content.Markdown_parser
open Memoir_content.Routing
open Stdio

(** Test the markdown parser *)
let test_markdown_parsing () =
  let markdown = "# Hello World\n\nThis is a test." in
  let html = parse_markdown markdown in
  check string "should convert markdown to HTML"
    "<h1 id=\"hello-world\">Hello World</h1>\n<p>This is a test.</p>\n" html

(** Test frontmatter extraction *)
let test_frontmatter_extraction () =
  (* Create a test content with very explicit frontmatter delimiters *)
  let content =
    "---\ntitle: Test Page\ndescription: A test page\n---\n# Content"
  in

  (* Debug printing to see what we're actually parsing *)
  Printf.printf "Testing content: %S\n" content;

  let yaml_opt, content_only = extract_frontmatter content in

  Printf.printf "Extracted YAML: %s\n"
    (match yaml_opt with
    | Some y -> "Some(" ^ y ^ ")"
    | None -> "None");
  Printf.printf "Content without frontmatter: %S\n" content_only;

  check bool "should extract frontmatter" true (Option.is_some yaml_opt);
  check string "should extract content without frontmatter" "# Content"
    (String.trim content_only);

  match yaml_opt with
  | Some yaml ->
      check string "should extract correct yaml"
        "title: Test Page\ndescription: A test page" yaml
  | None -> fail "Expected frontmatter to be extracted"

(** Test YAML frontmatter parsing *)
let test_frontmatter_parsing () =
  let yaml =
    "title: Test Page\n\
     description: A test page\n\
     tags:\n\
    \  - test\n\
    \  - example\n\
     draft: true"
  in
  let frontmatter = parse_yaml_frontmatter yaml in

  check string "should parse title" "Test Page" frontmatter.title;
  check (option string) "should parse description" (Some "A test page")
    frontmatter.description;
  check (list string) "should parse tags" [ "test"; "example" ] frontmatter.tags;
  check bool "should parse draft status" true frontmatter.draft

(** Test full markdown file parsing *)
let test_markdown_file_parsing () =
  (* Use explicit string with precise formatting *)
  let content =
    "---\ntitle: Test Page\ndescription: A test page\n---\n# Content"
  in

  (* Debug output *)
  Printf.printf "Original content: %S\n" content;

  (* Extract frontmatter for debugging *)
  let fm_yaml, content_only = extract_frontmatter content in
  Printf.printf "Extracted YAML: %s\n"
    (match fm_yaml with
    | Some y -> "Some(" ^ y ^ ")"
    | None -> "None");
  Printf.printf "Content without frontmatter: %S\n" content_only;

  (* Continue with the actual test *)
  let page = parse_markdown_file ~path:"test.md" ~content in

  Printf.printf "Page title: %S\n" page.frontmatter.title;

  check string "should set correct path" "test.md" page.path;
  check string "should parse title" "Test Page" page.frontmatter.title;
  check (option string) "should parse description" (Some "A test page")
    page.frontmatter.description;
  check string "should extract content" "# Content" (String.trim page.content);
  check bool "should generate HTML content" true
    (Option.is_some page.html_content);

  match page.html_content with
  | Some html ->
      check bool "HTML should contain h1 id" true
        (String.length html >= 7 && String.equal (String.sub html 0 7) "<h1 id=")
  | None -> fail "Expected HTML content to be generated"

(** Test URL path generation *)
let test_url_path_generation () =
  let path = "blog/my-first-post.md" in
  let url_path = path_to_url_path path in

  check string "should generate correct URL path" "/blog/my-first-post" url_path;

  let index_path = "index.md" in
  let index_url = path_to_url_path index_path in
  check string "should handle index files correctly" "/" index_url

(** Test routes generation *)
let test_route_generation () =
  let page =
    {
      path = "blog/my-post.md";
      frontmatter = { empty_frontmatter with title = "My Post" };
      content = "# Content";
      html_content = Some "<h1>Content</h1>";
      url_path = "/blog/my-post";
    }
  in

  let route = create_route page ~output_dir:"_site" in

  check string "should set correct source path" "blog/my-post.md"
    route.source_path;
  check string "should set correct output path" "_site/blog/my-post/index.html"
    route.output_path;
  check string "should set correct URL path" "/blog/my-post" route.url_path;
  check bool "should identify as post" true (route.content_type = Post)

let () =
  run "Content Component Tests"
    [
      ( "Markdown parsing",
        [
          test_case "Parse markdown to HTML" `Quick test_markdown_parsing;
          test_case "Parse complete markdown file" `Quick
            test_markdown_file_parsing;
        ] );
      ( "Frontmatter extraction",
        [
          test_case "Extract frontmatter from content" `Quick
            test_frontmatter_extraction;
          test_case "Parse YAML frontmatter" `Quick test_frontmatter_parsing;
        ] );
      ( "Routing",
        [
          test_case "Generate URL paths" `Quick test_url_path_generation;
          test_case "Generate routes" `Quick test_route_generation;
        ] );
    ]
