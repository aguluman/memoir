module Date : sig
  type t

  val of_string : string -> t option
  val to_iso_string : t -> string
  val compare : t -> t -> int
  val compare_opt_desc : t option -> t option -> int
  val year : t -> int
  val month : t -> int
  val day : t -> int
end

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

val empty_frontmatter : frontmatter

type content_page = {
  path : string;
  frontmatter : frontmatter;
  content : string;
  html_content : string option;
  url_path : string;
}

type content_type =
  | Page
  | Post
  | Project
  | Journal
  | Asset
