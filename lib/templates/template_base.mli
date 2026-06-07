(** Base HTML document layout shared by every page. *)

open Tyxml

(** The HTML5 doctype string. *)
val doctype : string

(** Assemble a full HTML document: [<head>] (title + standard meta tags +
    [additional_head]) and [<body>] (header / main / footer). The three content
    lists are flow content; [additional_head] holds extra head links/meta (e.g.
    the SEO block from {!Seo.Seo.make_head}). *)
val layout :
  ?lang:string ->
  title_text:string ->
  description:string ->
  page_class:string ->
  ?additional_head:Html_types.head_content_fun Html.elt list ->
  header_content:[< Html_types.flow5_without_header_footer ] Html.elt list ->
  content:[< Html_types.flow5 ] Html.elt list ->
  footer_content:[< Html_types.flow5_without_header_footer ] Html.elt list ->
  unit ->
  [> Html_types.html ] Html.elt
