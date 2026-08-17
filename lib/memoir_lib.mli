type config = {
  site_title : string;
  site_description : string;
  author : string;
  base_url : string;
  output_dir : string;
  content_dir : string;
}

val default_config : config
val site_domain : string
val read_file : string -> string
val write_file : string -> string -> unit
val ensure_directory_exists : string -> unit
val load_rss_pages : content_dir:string -> Content_types.content_page list
val generate_rss_feed : Content_types.content_page list -> config -> string
