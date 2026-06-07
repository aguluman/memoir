(* Site configuration — the single source of truth shared by both executables.
   Only the fields actually consumed survive: the RSS feed reads the metadata
   (site_title/description/author/base_url) and both bins agree on the build
   paths (output_dir/content_dir). *)
type config = {
  site_title : string;
  site_description : string;
  author : string;
  base_url : string;
  output_dir : string;
  content_dir : string;
}

let site_domain = "https://fearful-odds.rocks"

(* The one canonical configuration. The generator and the dev server both use
   this rather than each hand-rolling a near-identical literal. *)
let default_config =
  {
    site_title = "Chukwuma Akunyili's Blog";
    site_description =
      "Thoughts on software engineering, functional programming, and technology";
    author = "Chukwuma Akunyili";
    base_url = site_domain;
    output_dir = "_site";
    content_dir = "content";
  }

(* The processed-page model is the single canonical {!Content_types.content_page}
   (frontmatter + content + url). The RSS feed consumes that type directly rather
   than maintaining a parallel page/metadata record. *)

(* --- Filesystem helpers (shared by the generator and the dev server) ----- *)

(* Binary-safe read; closes the channel even on exception, and binary mode
   avoids CRLF translation that would corrupt images / shift byte counts. *)
let read_file path =
  try In_channel.with_open_bin path In_channel.input_all
  with Sys_error msg ->
    failwith (Printf.sprintf "Failed to read file %s: %s" path msg)

(* Create [dir] and any missing parents. *)
let rec ensure_directory_exists dir =
  if dir = "" || dir = "." || dir = "/" || Sys.file_exists dir then (
    if Sys.file_exists dir && not (Sys.is_directory dir) then
      failwith (Printf.sprintf "%s exists but is not a directory" dir))
  else (
    ensure_directory_exists (Filename.dirname dir);
    Sys.mkdir dir 0o755)

(* Binary-safe write; creates parent directories as needed. *)
let write_file path content =
  ensure_directory_exists (Filename.dirname path);
  try
    Out_channel.with_open_bin path (fun oc ->
        Out_channel.output_string oc content)
  with Sys_error msg ->
    failwith (Printf.sprintf "Failed to write file %s: %s" path msg)

(* --- Content loading for the RSS feed ------------------------------------ *)

(* Load blog and journal posts as {!Content_types.content_page}s. Single source
   of truth used by both bin/generator.ml and bin/server.ml; frontmatter is
   parsed by the same YAML parser the generator uses for pages. Ordering/limiting
   is left to {!generate_rss_feed}. *)
let load_rss_pages ~content_dir : Content_types.content_page list =
  let load subdir url_prefix =
    let dir = Filename.concat content_dir subdir in
    if Sys.file_exists dir && Sys.is_directory dir then
      Sys.readdir dir |> Array.to_list
      |> List.filter_map (fun file ->
          if Filename.check_suffix file ".md" && file <> "index.md" then (
            try
              let path = Filename.concat dir file in
              let content = read_file path in
              let fm =
                Memoir_content.Markdown_parser.frontmatter_of_content content
              in
              let slug = Filename.remove_extension file in
              (* No frontmatter block, or a keyless "Untitled" block, falls
                    back to the slug for the title. *)
              let fm =
                match fm with
                | None -> { Content_types.empty_frontmatter with title = slug }
                | Some f when f.Content_types.title = "Untitled" ->
                    { f with Content_types.title = slug }
                | Some f -> f
              in
              Some
                {
                  Content_types.path;
                  frontmatter = fm;
                  content;
                  html_content = None;
                  url_path = url_prefix ^ slug;
                }
            with Failure msg ->
              (* Surface (don't swallow) a malformed post; skip just that one
                    so a bad file can't take down the whole feed at runtime. *)
              Printf.eprintf "skipping RSS post %s: %s\n%!"
                (Filename.concat dir file) msg;
              None)
          else None)
    else []
  in
  load "pages/blog" "/blog/" @ load "pages/journal" "/journal/"

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

let rfc822_months =
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

let rfc822_days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |]

(* RFC822 pubDate for an item's parsed date. Total: the date is already known
   to be valid (it could only be built via Content_types.Date.of_string), so
   there is no parse step that can fail and no fallback branch. *)
let format_rfc822_date (d : Content_types.Date.t) =
  let open Content_types.Date in
  let tm =
    {
      Unix.tm_year = year d - 1900;
      tm_mon = month d - 1;
      tm_mday = day d;
      tm_hour = 0;
      tm_min = 0;
      tm_sec = 0;
      tm_wday = 0;
      tm_yday = 0;
      tm_isdst = false;
    }
  in
  let _, normalized_tm = Unix.mktime tm in
  Printf.sprintf "%s, %02d %s %04d 00:00:00 +0000"
    rfc822_days.(normalized_tm.tm_wday)
    (day d)
    rfc822_months.(month d)
    (year d)

(* Current time as an RFC822 stamp — for channel-level lastBuildDate/pubDate and
   for undated items. *)
let format_rfc822_now () =
  let tm = Unix.gmtime (Unix.time ()) in
  Printf.sprintf "%s, %02d %s %04d %02d:%02d:%02d +0000"
    rfc822_days.(tm.tm_wday) tm.tm_mday rfc822_months.(tm.tm_mon)
    (tm.tm_year + 1900) tm.tm_hour tm.tm_min tm.tm_sec

let generate_rss_item (page : Content_types.content_page) config =
  let fm = page.frontmatter in
  let title = escape_xml fm.title in
  let description =
    match fm.description with
    | Some s -> escape_xml s
    | None ->
        escape_xml
          (String.sub page.content 0 (min 200 (String.length page.content)))
  in
  let link = Printf.sprintf "%s%s" config.base_url page.url_path in
  let pub_date =
    match fm.date with
    | Some d -> format_rfc822_date d
    | None -> format_rfc822_now ()
  in
  let author_name = escape_xml config.author in

  (* Generate category tags *)
  let categories =
    List.map
      (fun tag ->
        Printf.sprintf "      <category>%s</category>" (escape_xml tag))
      fm.tags
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

let generate_rss_feed (pages : Content_types.content_page list) config =
  (* Filter out draft pages and sort by date (newest first) *)
  let published_pages =
    pages
    |> List.filter (fun (page : Content_types.content_page) ->
        not page.frontmatter.draft)
    |> List.sort (fun (a : Content_types.content_page) b ->
        Content_types.Date.compare_opt_desc a.frontmatter.date
          b.frontmatter.date)
    |> List.take 20 (* Limit to 20 most recent items (Stdlib, OCaml >= 5.3) *)
  in

  let items =
    List.map (fun page -> generate_rss_item page config) published_pages
  in
  let items_xml = String.concat "" items in

  let current_date = format_rfc822_now () in

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
