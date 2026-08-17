val extract_frontmatter : string -> string option * string
val parse_yaml_frontmatter : string -> Content_types.frontmatter
val frontmatter_of_content : string -> Content_types.frontmatter option
val parse_markdown : string -> string

val parse_markdown_file :
  path:string -> content:string -> Content_types.content_page
