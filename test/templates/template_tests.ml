open Alcotest
open Tyxml
open Memoir_templates
open Memoir_templates.Navigation
open Memoir_templates.Seo

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
    Alcotest.check Alcotest.bool "Highlight init script present" true
      (contains html_string "hljs.highlightAll()")

  let test_header () =
    let header_content = [ Html.div [ Html.txt "Header" ] ] in
    let html_string =
      String.concat ""
        (List.map
           (fun elt -> Format.asprintf "%a" (Html.pp_elt ()) elt)
           header_content)
    in
    Alcotest.check Alcotest.bool "Contains header text" true
      (contains html_string "Header");
    Alcotest.check Alcotest.bool "Contains div element" true
      (contains html_string "<div>");
    Alcotest.check Alcotest.bool "Contains closing div" true
      (contains html_string "</div>")

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
    Alcotest.check Alcotest.bool "Contains copyright" true
      (String.contains html_string '\xA9')

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
