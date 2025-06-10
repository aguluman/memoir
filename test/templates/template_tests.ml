open Alcotest
open Test_helpers
open Tyxml
open Memoir_templates
open Memoir_templates.Navigation
open Memoir_templates.Seo

module Template_tests = struct
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

    (* Helper function to check for string containment *)
    let contains_substring str sub =
      try
        let _ = Str.search_forward (Str.regexp_string sub) str 0 in
        true
      with Not_found -> false
    in

    (* Check for essential elements *)
    check bool "Contains page title" true (contains_substring html_string title);
    check bool "Contains description meta tag" true
      (contains_substring html_string description);
    check bool "Contains doctype declaration" true
      (contains_substring html_string "<!DOCTYPE html>");
    check bool "Contains language attribute" true
      (contains_substring html_string "lang=\"en\"");
    check bool "Contains page class" true
      (contains_substring html_string "class=\"test-page\"");
    check bool "Contains content" true
      (contains_substring html_string "Content");
    check bool "Contains header" true (contains_substring html_string "Header");
    check bool "Contains footer" true (contains_substring html_string "Footer");

    (* Check for essential CSS and JS resources *)
    check bool "Contains main.css link" true
      (contains_substring html_string "/static/css/main.css");
    check bool "Contains highlight.css link" true
      (contains_substring html_string "/static/css/highlight.css");
    check bool "Contains main.js script" true
      (contains_substring html_string "/static/js/main.js");
    check bool "Contains theme-toggle.js script" true
      (contains_substring html_string "/static/js/theme-toggle.js");
    check bool "Contains highlight.min.js script" true
      (contains_substring html_string "/static/js/highlight.min.js");

    (* Check for responsive meta tags *)
    check bool "Contains viewport meta" true
      (contains_substring html_string "viewport")

  let test_header () =
    let header_content = [ Html.div [ Html.txt "Header" ] ] in
    let html_string =
      String.concat ""
        (List.map
           (fun elt -> Format.asprintf "%a" (Html.pp_elt ()) elt)
           header_content)
    in
    let contains_substring str sub =
      try
        let _ = Str.search_forward (Str.regexp_string sub) str 0 in
        true
      with Not_found -> false
    in
    check bool "Contains header text" true
      (contains_substring html_string "Header");
    check bool "Contains div element" true
      (contains_substring html_string "<div>");
    check bool "Contains closing div" true
      (contains_substring html_string "</div>")

  let test_footer () =
    let current_year = (Unix.gmtime (Unix.time ())).tm_year + 1900 in
    let footer_content =
      [ Html.div [ Html.txt (Printf.sprintf "© %d Test User" current_year) ] ]
    in
    let html_string =
      String.concat ""
        (List.map
           (fun elt -> Format.asprintf "%a" (Html.pp_elt ()) elt)
           footer_content)
    in
    check bool "Contains copyright" true (String.contains html_string '\xA9')

  let test_navigation () =
    let nav = Navigation.make () in
    let html_string = Format.asprintf "%a" (Html.pp_elt ()) nav in
    check bool "Contains nav element" true (String.contains html_string '<')

  let test_seo () =
    let meta =
      Seo.make_head ~title_text:"Test" ~description:"Test"
        ~url:"https://example.com" ()
    in
    let html_string =
      String.concat ""
        (List.map (fun elt -> Format.asprintf "%a" (Html.pp_elt ()) elt) meta)
    in
    check bool "Contains meta tags" true (String.contains html_string 'm')
end

let () =
  run "Template System Tests"
    [
      ( "Template components",
        [
          test_case "Base layout" `Quick Template_tests.test_base_layout;
          test_case "Header" `Quick Template_tests.test_header;
          test_case "Footer" `Quick Template_tests.test_footer;
          test_case "Navigation" `Quick Template_tests.test_navigation;
          test_case "SEO" `Quick Template_tests.test_seo;
        ] );
    ]
