open QCheck
open Memoir_templates.Template_base

(* Helper function for substring check *)
let contains s sub =
  try Str.search_forward (Str.regexp_string sub) s 0 >= 0
  with Not_found -> false

(* Test theme toggle button presence *)
let test_theme_toggle_functionality () =
  let html =
    layout ~title_text:"Test" ~description:"Test desc" ~page_class:"test"
      ~header_content:[] ~content:[] ~footer_content:[] ()
  in
  let html_str = Format.asprintf "%a" (Tyxml.Html.pp ()) html in
  Alcotest.(check bool)
    "Theme toggle button present" true
    (contains html_str "theme-toggle");
  Alcotest.(check bool) "Sun icon present" true (contains html_str "☀️");
  Alcotest.(check bool) "Moon icon present" true (contains html_str "🌙")

(* Test code highlighting script presence *)
let test_code_highlighting () =
  let html =
    layout ~title_text:"Test" ~description:"Test desc" ~page_class:"test"
      ~header_content:[] ~content:[] ~footer_content:[] ()
  in
  let html_str = Format.asprintf "%a" (Tyxml.Html.pp ()) html in
  Alcotest.(check bool)
    "Highlight.js script present" true
    (contains html_str "hljs.highlightAll()")

(* QCheck property: Title is included in HTML *)
let title_property =
  Test.make ~name:"Title included in HTML" string_printable (fun title ->
      let html =
        layout ~title_text:title ~description:"Desc" ~page_class:"page"
          ~header_content:[] ~content:[] ~footer_content:[] ()
      in
      let html_str = Format.asprintf "%a" (Tyxml.Html.pp ()) html in
      contains html_str title)

(* QCheck property: Description is included in HTML *)
let description_property =
  Test.make ~name:"Description included in HTML" string_printable (fun desc ->
      let html =
        layout ~title_text:"Title" ~description:desc ~page_class:"page"
          ~header_content:[] ~content:[] ~footer_content:[] ()
      in
      let html_str = Format.asprintf "%a" (Tyxml.Html.pp ()) html in
      contains html_str desc)

(* Test error case: Empty title *)
let test_empty_title () =
  try
    let _ =
      layout ~title_text:"" ~description:"Desc" ~page_class:"page"
        ~header_content:[] ~content:[] ~footer_content:[] ()
    in
    Alcotest.(check bool) "Empty title handled" true true
  with _ -> Alcotest.fail "Empty title should not raise exception"

(* Test with additional head content *)
let test_additional_head () =
  let extra_script = Tyxml.Html.(script (txt "console.log('test');")) in
  let html =
    layout ~title_text:"Test" ~description:"Desc" ~page_class:"page"
      ~additional_head:[ extra_script ] ~header_content:[] ~content:[]
      ~footer_content:[] ()
  in
  let html_str = Format.asprintf "%a" (Tyxml.Html.pp ()) html in
  Alcotest.(check bool)
    "Additional head content included" true
    (contains html_str "console.log('test')")

let () =
  Alcotest.run "Client-Side JS Component Tests"
    [
      ( "Interactive features",
        [
          Alcotest.test_case "Theme toggle functionality" `Quick
            test_theme_toggle_functionality;
        ] );
      ( "DOM manipulation",
        [
          Alcotest.test_case "Code highlighting" `Quick test_code_highlighting;
          Alcotest.test_case "Empty title handling" `Quick test_empty_title;
          Alcotest.test_case "Additional head content" `Quick
            test_additional_head;
        ] );
    ];
  ignore
    (QCheck_runner.run_tests ~verbose:true
       [ title_property; description_property ])
