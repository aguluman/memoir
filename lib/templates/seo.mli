(** SEO and Open Graph metadata for page heads. *)

open Tyxml

module Seo : sig
  (** Head metadata for a page: a [rel="canonical"] link, the Open Graph tags,
      and — on [article] pages — [article:modified_time] / [article:author] when
      [modified] / [author] are supplied. [image] sets [og:image]. *)
  val make_head :
    title_text:string ->
    description:string ->
    url:string ->
    ?image:string ->
    ?type_:string ->
    ?modified:string ->
    ?author:string ->
    unit ->
    [> Html_types.link | Html_types.meta ] Html.elt list
end
