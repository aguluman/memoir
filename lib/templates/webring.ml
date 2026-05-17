open Tyxml

(** Webring navigation component *)
module Webring = struct
  (** Configuration for webring *)
  type webring_config = {
    webring_name : string;
    webring_url : string;
    member_id : string;
    base_url : string;
  }

  (** Default webring configuration *)
  let default_config =
    {
      webring_name = "ring.muhokama.fun";
      webring_url = "https://ring.muhokama.fun";
      (* My webring member ID *)
      member_id = "aguluman";
      base_url = "https://ring.muhokama.fun/u";
    }

  (** Generate webring navigation HTML *)
  let navigation ?(config = default_config) () =
    let open Html in
    div
      ~a:[ a_class [ "webring-nav" ] ]
      [
        div
          ~a:[ a_class [ "prev" ] ]
          [
            a
              ~a:
                [
                  a_href (config.base_url ^ "/" ^ config.member_id ^ "/pred");
                  a_class [ "webring-link"; "webring-prev" ];
                  a_title "Previous site in the webring";
                ]
              [ Html.txt "← Previous" ];
          ];
        div
          ~a:[ a_class [ "center" ] ]
          [
            Html.txt "Hey, this is part of ";
            a
              ~a:
                [
                  a_href config.webring_url;
                  a_target "_blank";
                  a_rel [ `Noopener; `Noreferrer ];
                ]
              [ Html.txt (config.webring_name ^ "!") ];
          ];
        div
          ~a:[ a_class [ "next" ] ]
          [
            a
              ~a:
                [
                  a_href (config.base_url ^ "/" ^ config.member_id ^ "/succ");
                  a_class [ "webring-link"; "webring-next" ];
                  a_title "Next site in the webring";
                ]
              [ Html.txt "Next →" ];
          ];
      ]
end
