open QCheck
open Memoir_content.Markdown_parser
open Memoir_content.Routing

(* Helper for substring check *)
let contains s sub =
  try Str.search_forward (Str.regexp_string sub) s 0 >= 0 with _ -> false

(* starts_with helper using Stdlib.String *)
let starts_with s pref =
  let ls = String.length s in
  let lp = String.length pref in
  ls >= lp && String.sub s 0 lp = pref

(* Test markdown parsing to HTML *)
let test_parse_markdown_to_html () =
  let md = "# Hello\n\nThis is **bold**." in
  let html = parse_markdown md in
  Alcotest.(check bool) "Contains Hello" true (contains html "Hello");
  Alcotest.(check bool) "Contains bold" true (contains html "bold")

(* Test complete markdown file parsing *)
let test_parse_complete_markdown_file () =
  let md = "---\ntitle: Test\ndescription: Desc\n---\n\n# Content" in
  let frontmatter, content = extract_frontmatter md in
  Alcotest.(check (option string))
    "Frontmatter extracted" (Some "title: Test\ndescription: Desc\n")
    frontmatter;
  Alcotest.(check bool) "Content parsed" true (contains content "# Content")

(* Test frontmatter extraction *)
let test_extract_frontmatter () =
  let content = "---\ntitle: Hello\n---\n\nBody" in
  let fm, body = extract_frontmatter content in
  Alcotest.(check (option string)) "YAML extracted" (Some "title: Hello\n") fm;
  Alcotest.(check string) "Body correct" "\nBody" body

(* Test YAML frontmatter parsing *)
let test_parse_yaml_frontmatter () =
  let yaml = "title: My Post\ndescription: A test\n" in
  let fm = parse_yaml_frontmatter yaml in
  Alcotest.(check string) "Title parsed" "My Post" fm.title;
  Alcotest.(check (option string))
    "Description parsed" (Some "A test") fm.description

(* Test URL path generation *)
let test_generate_url_paths () =
  Alcotest.(check string) "Index to root" "/" (path_to_url_path "index.md");
  Alcotest.(check string) "Page to path" "/about" (path_to_url_path "about.md")

(* Test route generation *)
let test_generate_routes () =
  let output = path_to_output_path "about.md" ~output_dir:"_site" in
  Alcotest.(check string) "Output path" "_site/about/index.html" output

(* QCheck: Frontmatter extraction with various content *)
let frontmatter_property =
  Test.make ~name:"Frontmatter extraction handles various inputs"
    string_printable (fun content ->
      try
        let fm, body = extract_frontmatter content in
        String.length body <= String.length content
        &&
        match fm with
        | Some _ -> starts_with content "---"
        | None -> true
      with _ -> false)

(* QCheck: URL path generation *)
let url_path_property =
  Test.make ~name:"URL paths are valid" string_printable (fun path ->
      let url = path_to_url_path (path ^ ".md") in
      (* URL should always start with '/' *)
      starts_with url "/")

(* Test error cases: Invalid YAML *)
let test_invalid_yaml () =
  let yaml = "not valid yaml" in
  let fm = parse_yaml_frontmatter yaml in
  Alcotest.(check string) "Fallback to empty" "Untitled" fm.title

let () =
  Alcotest.run "Content Component Tests"
    [
      ( "Markdown parsing",
        [
          Alcotest.test_case "Parse markdown to HTML" `Quick
            test_parse_markdown_to_html;
          Alcotest.test_case "Parse complete markdown file" `Quick
            test_parse_complete_markdown_file;
        ] );
      ( "Frontmatter extraction",
        [
          Alcotest.test_case "Extract frontmatter from content" `Quick
            test_extract_frontmatter;
          Alcotest.test_case "Parse YAML frontmatter" `Quick
            test_parse_yaml_frontmatter;
          Alcotest.test_case "Invalid YAML handling" `Quick test_invalid_yaml;
        ] );
      ( "Routing",
        [
          Alcotest.test_case "Generate URL paths" `Quick test_generate_url_paths;
          Alcotest.test_case "Generate routes" `Quick test_generate_routes;
        ] );
      ( "Properties",
        List.map QCheck_alcotest.to_alcotest
          [ frontmatter_property; url_path_property ] );
    ]
