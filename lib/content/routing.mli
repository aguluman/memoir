val path_to_url_path : string -> string
val path_to_output_path : string -> output_dir:string -> string
val classify : string -> Content_types.content_type
val resolve_url : site_root:string -> string -> string option
