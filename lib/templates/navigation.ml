open Tyxml

(** Responsive navigation menu component *)
module Navigation = struct
  (** Navigation link item with active state *)
  let nav_item ~href ~text ~current_path =
    let open Html in
    let is_active = href = current_path in
    let classes =
      if is_active then [ "nav-item"; "active" ] else [ "nav-item" ]
    in
    li
      ~a:[ a_class classes ]
      [
        a
          ~a:
            [
              a_href href;
              (if is_active then a_aria "current" [ "page" ]
               else a_user_data "no-attr" "true");
            ]
          [ Html.txt text ];
      ]

  (** Dropdown menu item *)
  let dropdown_item ~menu_title ~links =
    let open Html in
    let dropdown_id = String.lowercase_ascii menu_title ^ "-dropdown" in
    li
      ~a:[ a_class [ "nav-item"; "has-dropdown" ] ]
      [
        button
          ~a:
            [
              a_class [ "dropdown-toggle" ];
              a_aria "expanded" [ "false" ];
              a_aria "controls" [ dropdown_id ];
            ]
          [ Html.txt menu_title; span ~a:[ a_class [ "dropdown-icon" ] ] [] ];
        ul ~a:[ a_class [ "dropdown-menu" ]; a_id dropdown_id ] links;
      ]

  (** Social media navigation *)
  let social_nav =
    let open Html in
    ul
      ~a:[ a_class [ "social-nav" ] ]
      [
        li
          [
            a
              ~a:[ a_href "https://github.com"; a_aria "label" [ "GitHub" ] ]
              [ Html.txt "GitHub" ];
          ];
        li
          [
            a
              ~a:[ a_href "https://twitter.com"; a_aria "label" [ "Twitter" ] ]
              [ Html.txt "Twitter" ];
          ];
        li
          [
            a
              ~a:
                [ a_href "https://linkedin.com"; a_aria "label" [ "LinkedIn" ] ]
              [ Html.txt "LinkedIn" ];
          ];
      ]

  (** Mobile navigation toggle button *)
  let mobile_toggle () =
    let open Html in
    button
      ~a:
        [
          a_class [ "mobile-nav-toggle" ];
          a_aria "expanded" [ "false" ];
          a_aria "controls" [ "primary-navigation" ];
          a_aria "label" [ "Toggle navigation menu" ];
        ]
      [
        span ~a:[ a_class [ "hamburger" ] ] [];
        span ~a:[ a_class [ "sr-only" ] ] [ Html.txt "Menu" ];
      ]

  (** Main navigation component *)
  let make ?(current_path = "/") () =
    let open Html in
    nav
      ~a:[ a_class [ "site-navigation" ]; a_aria "label" [ "Main navigation" ] ]
      [
        mobile_toggle ();
        ul
          ~a:
            [
              a_class [ "nav-list" ];
              a_id "primary-navigation";
              a_user_data "visible" "false";
            ]
          [
            nav_item ~href:"/" ~text:"Home" ~current_path;
            nav_item ~href:"/about" ~text:"About" ~current_path;
            dropdown_item ~menu_title:"Projects"
              ~links:
                [
                  nav_item ~href:"/projects" ~text:"All Projects" ~current_path;
                  nav_item ~href:"/projects/web" ~text:"Web Development"
                    ~current_path;
                  nav_item ~href:"/projects/ocaml" ~text:"OCaml Projects"
                    ~current_path;
                ];
            nav_item ~href:"/blog" ~text:"Blog" ~current_path;
            nav_item ~href:"/journal" ~text:"Journal" ~current_path;
            nav_item ~href:"/contact" ~text:"Contact" ~current_path;
          ];
        div
          ~a:[ a_class [ "nav-right" ] ]
          [
            social_nav;
            (* Optional: Theme toggle or search button could go here *)
          ];
      ]
end
