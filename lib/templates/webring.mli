open Tyxml

module Webring : sig
  type config = {
    name : string;
    url : string;
    member_id : string;
    base_url : string;
  }

  val default_config : config
  val navigation : ?config:config -> unit -> [> Html_types.div ] Html.elt
end
