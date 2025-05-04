(** Content types for the Memoir static site generator *)

open Base

type frontmatter = {
  title : string;
  description : string option;
  date : string option;
  updated : string option;
  tags : string list;
  draft : bool;
  layout : string option;
  slug : string option;
  author : string option;
  featured_image : string option;
}
(** Frontmatter metadata for content pages *)

(** Default empty frontmatter *)
let empty_frontmatter =
  {
    title = "";
    description = None;
    date = None;
    updated = None;
    tags = [];
    draft = false;
    layout = None;
    slug = None;
    author = None;
    featured_image = None;
  }

type content_page = {
  path : string; (* File path relative to content directory *)
  frontmatter : frontmatter;
  content : string; (* Markdown content *)
  html_content : string option; (* Generated HTML content *)
  url_path : string; (* URL path for the generated page *)
}
(** A content page with frontmatter and markdown content *)

(** Content type for different sections of the site *)
type content_type = 
  | Page 
  | Post 
  | Project

(** Convert string to content_type *)
let content_type_of_string = function
  | "page" -> Page
  | "post" -> Post
  | "project" -> Project
  | _ -> Page (* Default to Page *)

(** Convert content_type to string *)
let string_of_content_type = function
  | Page -> "page"
  | Post -> "post"
  | Project -> "project"

type route = {
  source_path : string; (* Original source file path *)
  output_path : string; (* Output file path *)
  url_path : string; (* URL path *)
  content_type : content_type;
}
(** Route information for generating pages *)
