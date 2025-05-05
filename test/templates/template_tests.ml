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
    check bool "Contains title" true (String.contains html_string 'T');
    check bool "Contains content" true (String.contains html_string 'C')

  let test_header () =
    let header_content = [ Html.div [ Html.txt "Header" ] ] in
    let html_string =
      String.concat ""
        (List.map
           (fun elt -> Format.asprintf "%a" (Html.pp_elt ()) elt)
           header_content)
    in
    check bool "Contains header" true (String.contains html_string 'H')

  let test_footer () =
    let footer_content = [ Html.div [ Html.txt "© 2024 Test User" ] ] in
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
