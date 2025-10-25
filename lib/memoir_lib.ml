(* Basic configuration type for the static site generator *)
type config = {
  site_title : string;
  site_description : string;
  author : string;
  base_url : string;
  output_dir : string;
  content_dir : string;
  template_dir : string;
  static_dir : string;
}

(* Page metadata from frontmatter *)
type page_metadata = {
  title : string;
  date : string option;
  tags : string list;
  summary : string option;
  draft : bool;
}

(* Processed page content *)
type page = {
  metadata : page_metadata;
  content : string;
  url : string;
  source_path : string;
}

(* Default empty metadata *)
let empty_metadata =
  { title = "Untitled"; date = None; tags = []; summary = None; draft = false }

(* Parse YAML frontmatter from markdown content *)
let parse_frontmatter content =
  try
    (* Check if content starts with "---" *)
    let content_length = String.length content in
    if content_length > 6 && String.sub content 0 3 = "---" then
      (* Find the end of frontmatter (second "---") *)
      let rec find_end i =
        if i + 2 >= content_length then None
        else if String.sub content i 3 = "---" then Some i
        else find_end (i + 1)
      in
      match find_end 3 with
      | Some end_pos -> (
          let frontmatter = String.sub content 3 (end_pos - 3) in
          let remaining =
            String.sub content (end_pos + 3) (content_length - end_pos - 3)
          in
          (* Parse the YAML *)
          try
            let _yaml = Yaml.of_string frontmatter in
            (* Convert to metadata *)
            (* This is a basic implementation - expand with proper error handling *)
            (empty_metadata, remaining)
          with _ -> (empty_metadata, content))
      | None -> (empty_metadata, content)
    else (empty_metadata, content)
  with _ -> (empty_metadata, content)

(* Process markdown with frontmatter *)
let process_content file_path =
  try
    let content =
      Sys.readdir file_path |> ignore;
      "TODO: Implement file reading"
    in
    let metadata, _markdown = parse_frontmatter content in
    let html = "TODO: Convert markdown to HTML" in
    Some
      { metadata; content = html; url = "/TODO/url"; source_path = file_path }
  with _ -> None

(* Utility functions - to be implemented *)
let escape_xml s =
  let chars = String.to_seq s |> List.of_seq in
  let escaped =
    List.map
      (function
        | '&' -> "&amp;"
        | '<' -> "&lt;"
        | '>' -> "&gt;"
        | '"' -> "&quot;"
        | '\'' -> "&#39;"
        | c -> String.make 1 c)
      chars
  in
  String.concat "" escaped

let format_rfc822_date date_str =
  (* Convert ISO date to RFC822 format for RSS *)
  match date_str with
  | Some date -> (
      (* Parse YYYY-MM-DD format and convert to RFC822 *)
      try
        let parts = String.split_on_char '-' date in
        match parts with
        | [ year; month; day ] ->
            let year_int = int_of_string year in
            let month_int = int_of_string month in
            let day_int = int_of_string day in
            let months =
              [|
                "";
                "Jan";
                "Feb";
                "Mar";
                "Apr";
                "May";
                "Jun";
                "Jul";
                "Aug";
                "Sep";
                "Oct";
                "Nov";
                "Dec";
              |]
            in
            let month_name = months.(month_int) in
            (* Create a Unix time for day calculation *)
            let tm =
              {
                Unix.tm_year = year_int - 1900;
                tm_mon = month_int - 1;
                tm_mday = day_int;
                tm_hour = 0;
                tm_min = 0;
                tm_sec = 0;
                tm_wday = 0;
                tm_yday = 0;
                tm_isdst = false;
              }
            in
            let _, normalized_tm = Unix.mktime tm in
            let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
            let day_name = days.(normalized_tm.tm_wday) in
            Printf.sprintf "%s, %02d %s %04d 00:00:00 +0000" day_name day_int
              month_name year_int
        | _ -> Printf.sprintf "%s 00:00:00 +0000" date
      with _ -> Printf.sprintf "%s 00:00:00 +0000" date)
  | None ->
      (* Use current date as fallback *)
      let now = Unix.time () in
      let tm = Unix.gmtime now in
      let months =
        [|
          "Jan";
          "Feb";
          "Mar";
          "Apr";
          "May";
          "Jun";
          "Jul";
          "Aug";
          "Sep";
          "Oct";
          "Nov";
          "Dec";
        |]
      in
      let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
      Printf.sprintf "%s, %02d %s %04d %02d:%02d:%02d +0000" days.(tm.tm_wday)
        tm.tm_mday months.(tm.tm_mon) (tm.tm_year + 1900) tm.tm_hour tm.tm_min
        tm.tm_sec

let rec take n lst =
  match (n, lst) with
  | 0, _ -> []
  | _, [] -> []
  | n, x :: xs when n > 0 -> x :: take (n - 1) xs
  | _, _ -> []

let generate_rss_item page config =
  let title = escape_xml page.metadata.title in
  let description =
    match page.metadata.summary with
    | Some s -> escape_xml s
    | None ->
        escape_xml
          (String.sub page.content 0 (min 200 (String.length page.content)))
  in
  let link = Printf.sprintf "%s%s" config.base_url page.url in
  let pub_date = format_rfc822_date page.metadata.date in
  let author_name = escape_xml config.author in

  (* Generate category tags *)
  let categories =
    List.map
      (fun tag ->
        Printf.sprintf "      <category>%s</category>" (escape_xml tag))
      page.metadata.tags
  in
  let categories_xml = String.concat "\n" categories in

  Printf.sprintf
    {|
    <item>
      <title>%s</title>
      <link>%s</link>
      <description><![CDATA[%s]]></description>
      <dc:creator>%s</dc:creator>
      <pubDate>%s</pubDate>
      <guid isPermaLink="true">%s</guid>%s
    </item>|}
    title link description author_name pub_date link
    (if categories_xml = "" then "" else "\n" ^ categories_xml)

let generate_rss_feed pages config =
  (* Filter out draft pages and sort by date (newest first) *)
  let published_pages =
    pages
    |> List.filter (fun page -> not page.metadata.draft)
    |> List.sort (fun a b ->
        match (a.metadata.date, b.metadata.date) with
        | Some date_a, Some date_b -> String.compare date_b date_a
        | Some _, None -> -1
        | None, Some _ -> 1
        | None, None -> 0)
    |> take 20 (* Limit to 20 most recent items *)
  in

  let items =
    List.map (fun page -> generate_rss_item page config) published_pages
  in
  let items_xml = String.concat "" items in

  let current_date =
    let now = Unix.time () in
    let tm = Unix.gmtime now in
    let months =
      [|
        "Jan";
        "Feb";
        "Mar";
        "Apr";
        "May";
        "Jun";
        "Jul";
        "Aug";
        "Sep";
        "Oct";
        "Nov";
        "Dec";
      |]
    in
    let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
    Printf.sprintf "%s, %02d %s %04d %02d:%02d:%02d +0000" days.(tm.tm_wday)
      tm.tm_mday months.(tm.tm_mon) (tm.tm_year + 1900) tm.tm_hour tm.tm_min
      tm.tm_sec
  in

  Printf.sprintf
    {|<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>%s</title>
    <description>%s</description>
    <link>%s</link>
    <image>
      <url>%s/static/images/logo.svg</url>
      <title>%s</title>
      <link>%s</link>
    </image>
    <atom:link href="%s/feed.xml" rel="self" type="application/rss+xml" />
    <language>en</language>
    <lastBuildDate>%s</lastBuildDate>
    <pubDate>%s</pubDate>
    <ttl>60</ttl>
    <managingEditor>%s</managingEditor>
    <webMaster>%s</webMaster>%s
  </channel>
</rss>|}
    (escape_xml config.site_title) (* %s 1 *)
    (escape_xml config.site_description) (* %s 2 *)
    config.base_url (* %s 3 *) config.base_url (* %s 4 *)
    (escape_xml config.site_title) (* %s 5 *)
    config.base_url (* %s 6 *) config.base_url (* %s 7 *)
    current_date (* %s 8 *)
    current_date (* %s 9 *)
    (escape_xml config.author) (* %s 10 *)
    (escape_xml config.author) (* %s 11 *)
    items_xml (* %s 12 *)
