let chop_prefix ~prefix s =
  let pl = String.length prefix in
  if String.length s >= pl && String.sub s 0 pl = prefix then
    String.sub s pl (String.length s - pl)
  else s

let clean_base path =
  Filename.remove_extension path
  |> chop_prefix ~prefix:"content/"
  |> chop_prefix ~prefix:"pages/"
  |> String.map (function
    | '\\' -> '/'
    | c -> c)

let path_to_url_path content_path =
  let base = clean_base content_path in
  let url = if base = "index" then "/" else "/" ^ base in
  if String.ends_with ~suffix:"/index" url then Filename.dirname url else url

let path_to_output_path content_path ~output_dir =
  let base = clean_base content_path in
  if Filename.basename base = "index" then
    if base = "index" then Filename.concat output_dir "index.html"
    else Filename.concat output_dir (Filename.dirname base ^ "/index.html")
  else Filename.concat output_dir (base ^ "/index.html")

let classify path =
  match Filename.dirname path with
  | "content/blog" | "content/pages/blog" -> Content_types.Post
  | "content/projects" | "content/pages/projects" -> Content_types.Project
  | "content/journal" | "content/pages/journal" -> Content_types.Journal
  | "content/pages" | "content" -> Content_types.Page
  | _ when Filename.extension path = "" -> Content_types.Asset
  | _ -> Content_types.Page

let normalize_path path =
  let rec normalize acc = function
    | [] -> acc
    | "." :: rest -> normalize acc rest
    | ".." :: rest -> (
        match acc with
        | _ :: parent -> normalize parent rest
        | [] -> normalize [] rest)
    | x :: rest -> normalize (x :: acc) rest
  in
  let parts = String.split_on_char '/' path |> List.filter (fun s -> s <> "") in
  String.concat "/" (List.rev (normalize [] parts))

let resolve_url ~site_root url =
  let stripped =
    if url = "/" then "index"
    else if String.length url > 0 && url.[0] = '/' then
      String.sub url 1 (String.length url - 1)
    else url
  in
  let rel = normalize_path stripped in
  let candidates =
    [
      Filename.concat (Filename.concat site_root "static") rel;
      Filename.concat site_root rel;
      Filename.concat (Filename.concat site_root "pages") rel;
    ]
  in

  let concrete path =
    if Sys.file_exists path then
      if Sys.is_directory path then
        let idx = Filename.concat path "index.html" in
        if Sys.file_exists idx then idx else path
      else path
    else
      let html = path ^ ".html" in
      let dir_index = Filename.concat path "index.html" in
      if Sys.file_exists html then html
      else if Sys.file_exists dir_index then dir_index
      else path
  in
  let rec first = function
    | [] -> None
    | path :: rest ->
        let final = concrete path in
        if Sys.file_exists final && not (Sys.is_directory final) then Some final
        else first rest
  in
  first candidates
