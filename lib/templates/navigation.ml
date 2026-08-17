open Tyxml

module Navigation = struct
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
            ([ a_href href ]
            @ if is_active then [ a_aria "current" [ "page" ] ] else [])
          [ Html.txt text ];
      ]

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
            nav_item ~href:"/projects" ~text:"Projects" ~current_path;
            nav_item ~href:"/blog" ~text:"Blog" ~current_path;
            nav_item ~href:"/journal" ~text:"Journal" ~current_path;
            nav_item ~href:"/contact" ~text:"Contact" ~current_path;
          ];
      ]
end
