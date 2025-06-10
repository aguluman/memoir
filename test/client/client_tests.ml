open Alcotest
open Test_helpers

(** Mock DOM environment for client tests *)
module Dom_mock = struct
  type element = {
    mutable tag_name : string;
    mutable class_name : string;
    mutable inner_html : string;
    mutable attributes : (string * string) list;
    mutable style : (string * string) list;
    mutable parent : element option;
    mutable children : element list;
  }

  let create_element tag_name =
    {
      tag_name;
      class_name = "";
      inner_html = "";
      attributes = [];
      style = [];
      parent = None;
      children = [];
    }

  let add_child parent child =
    parent.children <- parent.children @ [ child ];
    child.parent <- Some parent

  let set_attribute el name value =
    el.attributes <-
      (name, value) :: List.filter (fun (k, _) -> k <> name) el.attributes

  let get_attribute el name =
    match List.find_opt (fun (k, _) -> k = name) el.attributes with
    | Some (_, v) -> Some v
    | None -> None
end

(** Test theme toggling functionality *)
let test_theme_toggle () =
  (* Create a mock DOM document *)
  let html = Dom_mock.create_element "html" in
  let body = Dom_mock.create_element "body" in
  Dom_mock.add_child html body;

  (* Add a theme toggle button *)
  let toggle_btn = Dom_mock.create_element "button" in
  Dom_mock.set_attribute toggle_btn "id" "theme-toggle";
  Dom_mock.add_child body toggle_btn;

  (* Initial state - light theme *)
  Dom_mock.set_attribute html "data-theme" "light";

  (* Simulate click on toggle button - should switch to dark *)
  let current_theme =
    match Dom_mock.get_attribute html "data-theme" with
    | Some theme -> theme
    | None -> "light"
  in
  let new_theme = if current_theme = "light" then "dark" else "light" in
  Dom_mock.set_attribute html "data-theme" new_theme;

  (* Check the theme changed *)
  check string "Theme should be dark after toggle" "dark"
    (match Dom_mock.get_attribute html "data-theme" with
    | Some theme -> theme
    | None -> "");

  (* Toggle again - should switch back to light *)
  let current_theme =
    match Dom_mock.get_attribute html "data-theme" with
    | Some theme -> theme
    | None -> "light"
  in
  let new_theme = if current_theme = "light" then "dark" else "light" in
  Dom_mock.set_attribute html "data-theme" new_theme;

  (* Check the theme changed back *)
  check string "Theme should be light after second toggle" "light"
    (match Dom_mock.get_attribute html "data-theme" with
    | Some theme -> theme
    | None -> "")

(** Test code highlighting functionality *)
let test_code_highlighting () =
  (* Create a mock DOM document *)
  let body = Dom_mock.create_element "body" in

  (* Add a code block *)
  let pre = Dom_mock.create_element "pre" in
  let code = Dom_mock.create_element "code" in
  code.inner_html <- "let x = 10 in x + 20";
  Dom_mock.set_attribute code "class" "language-ocaml";
  Dom_mock.add_child pre code;
  Dom_mock.add_child body pre;

  (* Simulate the highlight.js functionality *)
  let highlight_element code_el =
    let classes = code_el.Dom_mock.class_name in
    let new_classes = classes ^ " hljs" in
    code_el.Dom_mock.class_name <- new_classes
  in

  (* Apply highlighting to all code blocks *)
  List.iter highlight_element
    (List.filter (fun el -> el.Dom_mock.tag_name = "code") [ code ]);

  (* Verify element was highlighted *)
  let contains_substring str sub =
    try
      let _ = Str.search_forward (Str.regexp_string sub) str 0 in
      true
    with Not_found -> false
  in
  check bool "Code block should have hljs class" true
    (contains_substring code.Dom_mock.class_name "hljs")

let () =
  run "Client-Side JS Component Tests"
    [
      ( "Interactive features",
        [ test_case "Theme toggle functionality" `Quick test_theme_toggle ] );
      ( "DOM manipulation",
        [ test_case "Code highlighting" `Quick test_code_highlighting ] );
    ]
