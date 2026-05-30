open Tyxml

(** Webring navigation component.

    Single source of truth for the webring markup that appears at the bottom of
    every page. This deliberately mirrors the markup the generator used to embed
    as a raw string, so generated pages render identically. *)
module Webring = struct
  (** Configuration for a webring membership. *)
  type config = {
    name : string;  (** Display name, e.g. "ring.muhokama.fun" *)
    url : string;  (** Webring home page *)
    member_id : string;  (** This site's member id within the ring *)
    base_url : string;  (** Base URL for per-member pred/succ links *)
  }

  (** Default configuration for this site's webring membership. *)
  let default_config =
    {
      name = "ring.muhokama.fun";
      url = "https://ring.muhokama.fun";
      member_id = "aguluman";
      base_url = "https://ring.muhokama.fun/u";
    }

  (** Render the webring navigation block. *)
  let navigation ?(config = default_config) () =
    let open Html in
    let member base = config.base_url ^ "/" ^ config.member_id ^ base in
    div
      ~a:[ a_class [ "webring-nav" ] ]
      [
        a
          ~a:
            [
              a_href (member "/pred");
              a_class [ "webring-link"; "webring-prev"; "prev" ];
              a_title "Previous site in the webring";
            ]
          [ txt "← Pred" ];
        p
          ~a:[ a_class [ "webring-description"; "center" ] ]
          [
            txt "Hey, this site is part of ";
            a
              ~a:
                [
                  a_href config.url;
                  a_target "_blank";
                  a_rel [ `Noopener; `Noreferrer ];
                ]
              [ txt (config.name ^ "!") ];
          ];
        a
          ~a:
            [
              a_href (member "/succ");
              a_class [ "webring-link"; "webring-next"; "next" ];
              a_title "Next site in the webring";
            ]
          [ txt "Succ →" ];
      ]
end
