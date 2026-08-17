open Tyxml

val create_page :
  ?lang:string ->
  ?current_path:string ->
  ?page_class:string ->
  ?year:int ->
  ?author:string ->
  ?image:string ->
  ?modified:string ->
  title_text:string ->
  description:string ->
  content:Html_types.flow5 Html.elt list ->
  url:string ->
  unit ->
  string
