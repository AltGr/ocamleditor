(*

  OCamlEditor
  Copyright (C) 2010-2012 Francesco Tovagliari

  This file is part of OCamlEditor.

  OCamlEditor is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  OCamlEditor is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.

*)

open Printf
open Location
open Lexing
open Miscellanea


module Log = Common.Log.Make(struct let prefix = "Binannot" end)
let _ = Log.set_verbosity `DEBUG

type ident_kind = Def of Location.t | Int_ref of Location.t | Ext_ref

type ident = {
  mutable ident_fname : string;
  mutable ident_kind  : ident_kind;
  ident_name          : string;
  ident_loc           : Location.t;
}

type entry = { (* An entry collects all ident annotations of a source file. *)
  timestamp : float; (* mtime of the cmt file read *)
  locations : ident option array; (* Map from file offsets to idents *)
  int_refs  : (Location.t, ident) Hashtbl.t; (* Map from def's locations to all its internal refs. *)
  ext_refs  : (string, ident) Hashtbl.t; (* Map from module names (compilation units) to all external references  *)
}

let table_idents : (string, entry) Hashtbl.t = Hashtbl.create 7 (* source filename, entry *)

let string_of_kind = function
  | Def _ -> "Def"
  | Int_ref _ -> "Int_ref"
  | Ext_ref -> "Ext_ref"

let string_of_loc loc =
  let filename, a, b = Location.get_pos_info loc.loc_start in
  let _, c, d = Location.get_pos_info loc.loc_end in
  (*sprintf "%s, %d:%d(%d) -- %d:%d(%d)" filename a b (loc.loc_start.pos_cnum) c d (loc.loc_end.pos_cnum);;*)
  sprintf "%d--%d" (loc.loc_start.pos_cnum) (loc.loc_end.pos_cnum);;

let linechar_of_loc loc =
  let _, a, b = Location.get_pos_info loc.loc_start in
  let _, c, d = Location.get_pos_info loc.loc_end in
  ((a - 1), b), ((c - 1), d)

let string_of_type_expr te = Odoc_info.string_of_type_expr te;;

let (<==) loc offset = loc.loc_start.pos_cnum <= offset && offset <= loc.loc_end.pos_cnum

(** read_cmt *)
let read_cmt ~project ~filename:source ?(timestamp=0.) ?compile_buffer () =
  try
    let result =
      let ext = if source ^^ ".ml" then Some ".cmt" else if source ^^ ".mli" then Some ".cmti" else None in
      match ext with
        | Some ext ->
          Opt.map_default (Project.tmp_of_abs project source) None begin fun (tmp, relname) ->
            let source_tmp = tmp // relname in
            let source_avail =
              if Sys.file_exists source_tmp then source_tmp
              else begin
                match compile_buffer with
                  | Some f ->
                    f();
                    source_tmp
                  | None -> source
              end
            in
            let cmt = (Filename.chop_extension source_avail) ^ ext in
            let mtime_cmt = (Unix.stat cmt).Unix.st_mtime in
            if mtime_cmt = timestamp then None else begin
              let mtime_src = (Unix.stat source_avail).Unix.st_mtime in
              if mtime_cmt >= mtime_src then begin
                Some (source, mtime_cmt, Cmt_format.read_cmt cmt)
              end else None
            end;
          end;
        | _ -> kprintf invalid_arg "Binannot.read \"%s\"" source
      in
      result
  with
    | Unix.Unix_error (Unix.ENOENT as err, "stat", _) as ex ->
      Log.println `WARN "%s - %s" (Printexc.to_string ex) (Unix.error_message err);
      None
    | Unix.Unix_error (err, _, _) as ex ->
      Log.println `ERROR "%s - %s" (Printexc.to_string ex) (Unix.error_message err);
      None
    | ex ->
      Log.println `ERROR "%s" (Printexc.to_string ex);
      None
;;

(** print_ident *)
let print_ident {ident_kind; ident_name; ident_loc; _} =
  let loc' =
    match ident_kind with
      | Def loc -> "scope: " ^ (string_of_loc loc)
      | Int_ref def -> "def: " ^ (string_of_loc def)
      | Ext_ref -> ""
  in
  printf "%-7s: %-30s (%-12s) (%-19s) %s\n%!"
    (String.uppercase (string_of_kind ident_kind))
    ident_name (string_of_loc ident_loc) loc' ident_loc.loc_start.pos_fname;
;;




