(** Content types for the Memoir static site generator *)

(** A calendar date, parsed from an ISO ["YYYY-MM-DD"] frontmatter string.

    The constructor is private to {!Date.of_string}, which returns [None] for
    anything that isn't a valid date. That keeps unparseable dates out of the
    model entirely (Minsky: "make illegal states unrepresentable") rather than
    storing a raw string and re-parsing — and failing — at every use site. *)
module Date = struct
  type t = {
    year : int;
    month : int;
    day : int;
  }

  (** Parse ["YYYY-MM-DD"]. Returns [None] for any malformed or out-of-range
      input, so a bad date can never be constructed. *)
  let of_string s =
    match String.split_on_char '-' s with
    | [ y; m; d ] -> (
        match
          (int_of_string_opt y, int_of_string_opt m, int_of_string_opt d)
        with
        | Some year, Some month, Some day
          when month >= 1 && month <= 12 && day >= 1 && day <= 31 ->
            Some { year; month; day }
        | _ -> None)
    | _ -> None

  (** Render back to ISO ["YYYY-MM-DD"] — the on-page display form. *)
  let to_iso_string { year; month; day } =
    Printf.sprintf "%04d-%02d-%02d" year month day

  (* Component accessors — the type is abstract across the interface, so callers
     that need the parts (e.g. RFC822 formatting) go through these rather than
     reaching into the record. *)
  let year t = t.year
  let month t = t.month
  let day t = t.day

  (** Total chronological order (oldest < newest). Monomorphic [Int.compare]
      rather than polymorphic [compare], per Jane Street style. *)
  let compare a b =
    match Int.compare a.year b.year with
    | 0 -> (
        match Int.compare a.month b.month with
        | 0 -> Int.compare a.day b.day
        | c -> c)
    | c -> c

  (** Newest-first comparator for [date option] sort keys; undated sorts last.
  *)
  let compare_opt_desc a b =
    match (a, b) with
    | Some x, Some y -> compare y x
    | Some _, None -> -1
    | None, Some _ -> 1
    | None, None -> 0
end

(** Frontmatter metadata for content pages *)
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

(** A content page with frontmatter and markdown content *)
type content_page = {
  path : string; (* File path relative to content directory *)
  frontmatter : frontmatter;
  content : string; (* Markdown content *)
  html_content : string option; (* Generated HTML content *)
  url_path : string; (* URL path for the generated page *)
}

(** Content type for different sections of the site *)
type content_type =
  | Page
  | Post
  | Project
  | Journal
  | Asset  (** Non-markdown file copied through verbatim *)
