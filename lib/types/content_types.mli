(** Content types for the Memoir static site generator. *)

(** A calendar date parsed from an ISO ["YYYY-MM-DD"] frontmatter string.

    [t] is abstract and can only be produced by {!Date.of_string}, which rejects
    anything malformed. An invalid date is therefore unrepresentable — there is
    no way to construct one and no later parse step that can fail. *)
module Date : sig
  type t

  (** Parse ["YYYY-MM-DD"]; [None] for any malformed or out-of-range input. *)
  val of_string : string -> t option

  (** Render back to ISO ["YYYY-MM-DD"]. *)
  val to_iso_string : t -> string

  (** Total chronological order (oldest < newest). *)
  val compare : t -> t -> int

  (** Newest-first comparator for [t option] sort keys; undated sorts last. *)
  val compare_opt_desc : t option -> t option -> int

  val year : t -> int
  val month : t -> int
  val day : t -> int
end

(** Frontmatter metadata for content pages. *)
type frontmatter = {
  title : string;
  description : string option;
  date : Date.t option;
  updated : Date.t option;
  tags : string list;
  draft : bool;
  layout : string option;
  slug : string option;
  author : string option;
  featured_image : string option;
}

(** Empty frontmatter. A [title = ""] result signals "no frontmatter block at
    all"; a present-but-titleless block yields the ["Untitled"] default. *)
val empty_frontmatter : frontmatter

(** A content page with frontmatter and (optionally rendered) markdown content.
*)
type content_page = {
  path : string;  (** File path relative to the content directory. *)
  frontmatter : frontmatter;
  content : string;  (** Markdown content. *)
  html_content : string option;  (** Generated HTML content, if rendered. *)
  url_path : string;  (** URL path for the generated page. *)
}

(** The section a content file belongs to. *)
type content_type =
  | Page
  | Post
  | Project
  | Journal
  | Asset  (** Non-markdown file copied through verbatim. *)
