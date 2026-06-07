(** Webring navigation component: the single source of truth for the webring
    markup at the bottom of every page. *)

open Tyxml

module Webring : sig
  (** Configuration for a webring membership. *)
  type config = {
    name : string;  (** Display name, e.g. "ring.muhokama.fun". *)
    url : string;  (** Webring home page. *)
    member_id : string;  (** This site's member id within the ring. *)
    base_url : string;  (** Base URL for per-member pred/succ links. *)
  }

  (** Default configuration for this site's webring membership. *)
  val default_config : config

  (** Render the webring navigation block. *)
  val navigation : ?config:config -> unit -> [> Html_types.div ] Html.elt
end
