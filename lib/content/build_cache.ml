type t = {
  file_hashes : (string * string) list; (* path, content hash *)
  cache_file : string;
}

let read_file path = In_channel.with_open_bin path In_channel.input_all
let hash_file path = Digest.to_hex (Digest.string (read_file path))
let empty ~cache_file = { file_hashes = []; cache_file }

let load ~cache_file =
  match read_file cache_file with
  | content ->
      let file_hashes =
        String.split_on_char '\n' content
        |> List.filter_map (fun line ->
            match String.split_on_char '|' line with
            | [ path; hash ] -> Some (path, hash)
            | _ -> None (* skip blank/old-format lines *))
      in
      { file_hashes; cache_file }
  | exception Sys_error _ ->
      (* Absent on the first build — start empty. *)
      { file_hashes = []; cache_file }

let index_path_for = function
  | Content_types.Post -> Some "content/pages/blog/index.md"
  | Content_types.Journal -> Some "content/pages/journal/index.md"
  | _ -> None

let is_index_page file_path =
  String.ends_with ~suffix:"/index.md" file_path
  &&
  match Routing.classify file_path with
  | Content_types.Post | Content_types.Journal -> true
  | _ -> false

let needs_rebuild t file_path =
  try
    if is_index_page file_path then true
    else
      let current = hash_file file_path in
      match List.find_opt (fun (p, _) -> p = file_path) t.file_hashes with
      | Some (_, last) when last <> "" -> current <> last
      | _ -> true (* no entry / empty hash -> rebuild *)
  with Sys_error _ -> true (* unreadable -> rebuild *)

let record t file_path =
  let with_entry =
    try
      let current = hash_file file_path in
      {
        t with
        file_hashes =
          (file_path, current)
          :: List.filter (fun (p, _) -> p <> file_path) t.file_hashes;
      }
    with Sys_error _ -> t
  in

  match index_path_for (Routing.classify file_path) with
  | Some index_path when file_path <> index_path ->
      {
        with_entry with
        file_hashes =
          List.filter (fun (p, _) -> p <> index_path) with_entry.file_hashes;
      }
  | _ -> with_entry

let save t =
  let content =
    String.concat "\n"
      (List.map (fun (p, h) -> Printf.sprintf "%s|%s" p h) t.file_hashes)
  in
  Out_channel.with_open_bin t.cache_file (fun oc ->
      Out_channel.output_string oc content)
