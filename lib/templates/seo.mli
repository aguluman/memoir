open Tyxml

module Seo : sig
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
