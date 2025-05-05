open Tyxml

(** Header component for all pages *)
module Header = struct
  (** Site logo component *)
  let logo ?(alt = "Site Logo") ?(src = "/static/images/logo.svg")
      ?(width = "150") ?(height = "50") () =
    let open Html in
    a
      ~a:[ a_href "/" ]
      [
        img ~src ~alt
          ~a:[ a_width (int_of_string width); a_height (int_of_string height) ]
          ();
      ]

  (** Navigation menu links *)
  let nav_links =
    let open Html in
    [
      li [ a ~a:[ a_href "/" ] [ Html.txt "Home" ] ];
      li [ a ~a:[ a_href "/about" ] [ Html.txt "About" ] ];
      li [ a ~a:[ a_href "/projects" ] [ Html.txt "Projects" ] ];
      li [ a ~a:[ a_href "/blog" ] [ Html.txt "Blog" ] ];
      li [ a ~a:[ a_href "/journal" ] [ Html.txt "Journal" ] ];
      (* Daily Entry: a recollection of how my day was spent *)
      li [ a ~a:[ a_href "/contact" ] [ Html.txt "Contact" ] ];
    ]

  (** Mobile navigation toggle button *)
  let nav_toggle () =
    let open Html in
    button
      ~a:
        [
          a_class [ "nav-toggle" ];
          a_aria "expanded" [ "false" ];
          a_aria "controls" [ "primary-navigation" ];
          a_aria "label" [ "Toggle navigation menu" ];
        ]
      [
        span ~a:[ a_class [ "sr-only" ] ] [ Html.txt "Menu" ];
        span ~a:[ a_class [ "icon-bar" ] ] [];
        span ~a:[ a_class [ "icon-bar" ] ] [];
        span ~a:[ a_class [ "icon-bar" ] ] [];
      ]

  (** Responsive navigation menu *)
  let navigation () =
    let open Html in
    nav
      ~a:
        [
          a_class [ "primary-navigation" ];
          a_id "primary-navigation";
          a_aria "label" [ "Main" ];
        ]
      [ ul ~a:[ a_class [ "nav-links" ] ] nav_links ]

  (** Complete header component *)
  let make ?(show_logo = true) () =
    let open Html in
    header
      ~a:[ a_class [ "site-header" ] ]
      [
        div
          ~a:[ a_class [ "container" ]; a_class [ "header-container" ] ]
          [
            (if show_logo then logo () else span []);
            nav_toggle ();
            navigation ();
          ];
      ]
end
