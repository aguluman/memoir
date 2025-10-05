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
            ([ a_href href ]
            @ if is_active then [ a_aria "current" [ "page" ] ] else [])
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

  (** Social media icons as SVG *)
  let github_icon =
    let open Html in
    svg
      ~a:
        [
          Svg.a_width (20., None);
          Svg.a_height (20., None);
          Svg.a_viewBox (0., 0., 24., 24.);
          Svg.a_fill (`Color ("currentColor", None));
          Svg.a_class [ "social-icon" ];
        ]
      [
        Svg.path
          ~a:
            [
              Svg.a_d
                "M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 \
                 11.385.6.105.825-.255.825-.57 \
                 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 \
                 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 \
                 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 \
                 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 \
                 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 \
                 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 \
                 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 \
                 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 \
                 .315.225.69.825.57A12.02 12.02 0 0024 \
                 12c0-6.63-5.37-12-12-12z";
            ]
          [];
      ]

  let x_icon =
    let open Html in
    svg
      ~a:
        [
          Svg.a_width (20., None);
          Svg.a_height (20., None);
          Svg.a_viewBox (0., 0., 24., 24.);
          Svg.a_fill (`Color ("currentColor", None));
          Svg.a_class [ "social-icon" ];
        ]
      [
        Svg.path
          ~a:
            [
              Svg.a_d
                "M18.244 2.25h3.308l-7.227 8.26 8.502 \
                 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 \
                 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z";
            ]
          [];
      ]

  let linkedin_icon =
    let open Html in
    svg
      ~a:
        [
          Svg.a_width (20., None);
          Svg.a_height (20., None);
          Svg.a_viewBox (0., 0., 24., 24.);
          Svg.a_fill (`Color ("currentColor", None));
          Svg.a_class [ "social-icon" ];
        ]
      [
        Svg.path
          ~a:
            [
              Svg.a_d
                "M20.447 \
                 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 \
                 0-2.136 1.445-2.136 \
                 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 \
                 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 \
                 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 \
                 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 \
                 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 \
                 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 \
                 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 \
                 22.222 0h.003z";
            ]
          [];
      ]

  (** Social media navigation with icons *)
  let social_nav =
    let open Html in
    ul
      ~a:[ a_class [ "social-nav" ] ]
      [
        li
          [
            a
              ~a:
                [
                  a_href "https://github.com/aguluman";
                  a_aria "label" [ "GitHub" ];
                  a_title "GitHub";
                  a_class [ "social-link" ];
                  a_rel [ `Noopener; `Noreferrer ];
                  a_target "_blank";
                ]
              [
                github_icon;
                span ~a:[ a_class [ "visually-hidden" ] ] [ Html.txt "GitHub" ];
              ];
          ];
        li
          [
            a
              ~a:
                [
                  a_href "https://x.com/agulumans";
                  a_aria "label" [ "X" ];
                  a_title "X";
                  a_class [ "social-link" ];
                  a_rel [ `Noopener; `Noreferrer ];
                  a_target "_blank";
                ]
              [
                x_icon;
                span ~a:[ a_class [ "visually-hidden" ] ] [ Html.txt "Twitter" ];
              ];
          ];
        li
          [
            a
              ~a:
                [
                  a_href "https://www.linkedin.com/in/chukwuma-akunyili/";
                  a_aria "label" [ "LinkedIn" ];
                  a_title "LinkedIn";
                  a_class [ "social-link" ];
                  a_rel [ `Noopener; `Noreferrer ];
                  a_target "_blank";
                ]
              [
                linkedin_icon;
                span
                  ~a:[ a_class [ "visually-hidden" ] ]
                  [ Html.txt "LinkedIn" ];
              ];
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
            nav_item ~href:"/projects" ~text:"Projects" ~current_path;
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
