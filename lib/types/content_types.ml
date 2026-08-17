module Date = struct
  type t = {
    year : int;
    month : int;
    day : int;
  }

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

  let to_iso_string { year; month; day } =
    Printf.sprintf "%04d-%02d-%02d" year month day

  let year t = t.year
  let month t = t.month
  let day t = t.day

  let compare a b =
    match Int.compare a.year b.year with
    | 0 -> (
        match Int.compare a.month b.month with
        | 0 -> Int.compare a.day b.day
        | c -> c)
    | c -> c

  let compare_opt_desc a b =
    match (a, b) with
    | Some x, Some y -> compare y x
    | Some _, None -> -1
    | None, Some _ -> 1
    | None, None -> 0
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
