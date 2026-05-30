open Alcotest
open Tyxml
open Memoir_templates
open Memoir_templates.Navigation
open Memoir_templates.Seo
open Memoir_templates.Footer
open Memoir_templates.Webring

module Template_tests = struct
  let contains s sub =
    try Str.search_forward (Str.regexp_string sub) s 0 >= 0 with _ -> false

  let test_base_layout () =
    let title = "Test Page" in
    let description = "Test description" in
    let layout =
      Template_base.layout ~title_text:title ~description
        ~page_class:"test-page"
        ~header_content:[ Html.div [ Html.txt "Header" ] ]
        ~content:[ Html.p [ Html.txt "Content" ] ]
        ~footer_content:[ Html.div [ Html.txt "Footer" ] ]
        ()
    in
    let html_string = Format.asprintf "%a" (Html.pp ()) layout in

    (* Check doctype, title tag and meta description explicitly *)
    Alcotest.check Alcotest.bool "Has doctype" true
      (contains html_string "<!DOCTYPE");
    Alcotest.check Alcotest.bool "Has title tag" true
      (contains html_string "<title>");
    Alcotest.check Alcotest.bool "Contains title text" true
      (contains html_string title);
    Alcotest.check Alcotest.bool "Contains description" true
      (contains html_string description);

    (* Ensure theme toggle button and script hooks are present *)
    Alcotest.check Alcotest.bool "Theme toggle class present" true
      (contains html_string "theme-toggle");
    (* Highlighting is loaded via the external highlight.min.js script, not an
       inline init call in the head. *)
    Alcotest.check Alcotest.bool "Highlight script present" true
      (contains html_string "highlight.min.js")

  (* Exercises the real Webring component (now the single source of truth for
     the webring markup that the generator used to inline as a string). *)
  let test_webring () =
    let html_string =
      Format.asprintf "%a" (Html.pp_elt ()) (Webring.navigation ())
    in
    Alcotest.check Alcotest.bool "Has webring container" true
      (contains html_string "webring-nav");
    Alcotest.check Alcotest.bool "Has previous link" true
      (contains html_string "Pred");
    Alcotest.check Alcotest.bool "Has next link" true
      (contains html_string "Succ");
    Alcotest.check Alcotest.bool "Links to ring member" true
      (contains html_string "ring.muhokama.fun/u/aguluman")

  (* Exercises the real Footer.copyright component. *)
  let test_footer () =
    let current_year = (Unix.gmtime (Unix.time ())).tm_year + 1900 in
    let html_string =
      Format.asprintf "%a" (Html.pp_elt ())
        (Footer.copyright ~year:current_year ~name:"Test User" ())
    in
    Alcotest.check Alcotest.bool "Contains copyright symbol" true
      (String.contains html_string '\xA9');
    Alcotest.check Alcotest.bool "Contains name" true
      (contains html_string "Test User");
    Alcotest.check Alcotest.bool "Contains year" true
      (contains html_string (string_of_int current_year))

  let test_navigation () =
    let nav = Navigation.make () in
    let html_string = Format.asprintf "%a" (Html.pp_elt ()) nav in
    Alcotest.check Alcotest.bool "Contains nav element" true
      (contains html_string "nav")

  let test_seo () =
    let meta =
      Seo.make_head ~title_text:"Test" ~description:"Test"
        ~url:"https://example.com" ()
    in
    let html_string =
      String.concat ""
        (List.map (fun elt -> Format.asprintf "%a" (Html.pp_elt ()) elt) meta)
    in
    (* Check canonical url link presence and an Open Graph meta tag *)
    Alcotest.check Alcotest.bool "Contains canonical link" true
      (contains html_string "rel=\"canonical\"");
    Alcotest.check Alcotest.bool "Contains og:title" true
      (contains html_string "og:title")

  (* Full page assembly: verifies create_page wires together navigation, title,
     body content, footer copyright, the webring, and the canonical link. *)
  let test_create_page () =
    let html =
      Templates.create_page ~current_path:"/about" ~year:2026 ~author:"Tester"
        ~title_text:"About" ~description:"About page"
        ~content:[ Html.div [ Html.txt "Body text here" ] ]
        ~url:"https://example.com/about" ()
    in
    Alcotest.check Alcotest.bool "Has doctype" true (contains html "<!DOCTYPE");
    Alcotest.check Alcotest.bool "Title text present" true
      (contains html "About");
    Alcotest.check Alcotest.bool "Navigation present" true
      (contains html "site-navigation");
    Alcotest.check Alcotest.bool "Body content present" true
      (contains html "Body text here");
    Alcotest.check Alcotest.bool "Footer copyright present" true
      (contains html "Tester");
    Alcotest.check Alcotest.bool "Webring present" true
      (contains html "webring-nav");
    Alcotest.check Alcotest.bool "Canonical link present" true
      (contains html "rel=\"canonical\"");
    Alcotest.check Alcotest.bool "Canonical URL present" true
      (contains html "https://example.com/about")
end

let () =
  run "Template System Tests"
    [
      ( "Template components",
        [
          test_case "Base layout" `Quick Template_tests.test_base_layout;
          test_case "Create page" `Quick Template_tests.test_create_page;
          test_case "Footer" `Quick Template_tests.test_footer;
          test_case "Navigation" `Quick Template_tests.test_navigation;
          test_case "Webring" `Quick Template_tests.test_webring;
          test_case "SEO" `Quick Template_tests.test_seo;
        ] );
    ]
