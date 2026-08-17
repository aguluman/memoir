open Tyxml

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
