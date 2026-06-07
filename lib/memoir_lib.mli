(** Shared library for the Memoir generator and dev server: filesystem helpers
    plus RSS-feed loading and rendering. The processed-page model is the single
    canonical {!Content_types.content_page}. *)

(** Site configuration: RSS metadata plus the build paths both executables
    share. *)
type config = {
  site_title : string;
  site_description : string;
  author : string;
  base_url : string;
  output_dir : string;
  content_dir : string;
}

(** The single canonical site configuration used by the generator and server. *)
val default_config : config

(** Canonical public domain of the site, used to build absolute URLs. *)
val site_domain : string

(** Binary-safe read of an entire file; raises [Failure] on IO error. *)
val read_file : string -> string

(** Binary-safe write, creating parent directories as needed; raises [Failure]
    on IO error. *)
val write_file : string -> string -> unit

(** Create a directory and any missing parents. *)
val ensure_directory_exists : string -> unit

(** Load blog and journal posts (excluding [index.md]) as content pages, with
    each page's [url_path] set to its section URL. Ordering/limiting is left to
    {!generate_rss_feed}. *)
val load_rss_pages : content_dir:string -> Content_types.content_page list

(** Render an RSS 2.0 feed: drop drafts, sort newest-first, keep the 20 most
    recent items. *)
val generate_rss_feed : Content_types.content_page list -> config -> string
