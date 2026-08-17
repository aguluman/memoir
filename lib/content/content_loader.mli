type entry = {
  title : string;
  date : Content_types.Date.t option;
  description : string option;
  url : string;
}

val walk_files : string -> string list
val list_entries : dir:string -> url_prefix:string -> entry list
