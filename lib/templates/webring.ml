open Tyxml

module Webring = struct
  type config = {
    name : string;
    url : string;
    member_id : string;
    base_url : string;
  }

  let default_config =
    {
      name = "ring.muhokama.fun";
      url = "https://ring.muhokama.fun";
      member_id = "aguluman";
      base_url = "https://ring.muhokama.fun/u";
    }

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
