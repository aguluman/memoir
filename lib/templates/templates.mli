(** Page assembly: combine navigation, SEO head, body content, webring and
    footer into a complete HTML document string. *)

open Tyxml

(** Render a complete HTML page to a string.

    [content] is the page body (flow content); the webring block is appended
    automatically. [image] sets the Open Graph image and [modified] the article
    modified-time — both only meaningful on non-home (article) pages, where
    [author] is also emitted as [article:author]. *)
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
