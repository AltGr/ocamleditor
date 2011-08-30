(*

  OCamlEditor
  Copyright (C) 2010, 2011 Francesco Tovagliari

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

type location = {
  kind : kind;
  filename : string;
  mutable mark : Gtk.text_mark option;
  mutable offset : int
} and kind = [`EDIT | `BROWSE]

type t = {
  mutable current : int;
  mutable history : location list;
}

let proximity = Oe_config.location_history_proximity (* in characters *)
let limit_hint = Oe_config.location_history_max_length (* max length of history *)

(** create *)
let create () = {
  current = 0;
  history = [];
}

(** string_of_location *)
let string_of_location loc =
  let label = sprintf "%s (%s)" (Filename.basename loc.filename) in
  match loc.mark with
    | None -> label (string_of_int loc.offset)
    | Some mark ->
      begin
        match GtkText.Mark.get_buffer mark with
          | None ->
            let deleted = GtkText.Mark.get_deleted mark in
            let name = Gaux.default "NN" ~opt:(GtkText.Mark.get_name mark) in
            eprintf "%s %d name=%s; deleted=%b\n%!" loc.filename loc.offset name deleted;
            (*assert false*)
            label name
          | Some buffer ->
            let iter = Gmisclib.Util.get_iter_at_mark_safe buffer mark in
            kprintf label "%d : %d" (GtkText.Iter.get_line iter + 1) (GtkText.Iter.get_line_offset iter)
      end

(** iter *)
let iter nh ~f = List.iter f nh.history

(** current_index *)
let current_index nh = nh.current

(** length *)
let length nh = List.length nh.history

(** create_mark *)
let create_mark ~(buffer : GText.buffer) ~offset =
  let ts = Unix.gettimeofday() in
  buffer#create_mark ~name:(sprintf "%f" ts) (buffer#get_iter (`OFFSET offset))

(** divide' *)
let divide' n ll =
  let rec loop prior subs n =
    if n <= 0 then (prior, subs) else begin
      match subs with
        | [] -> prior, subs
        | a :: b -> loop (a :: prior) b (n - 1)
    end
  in
  let a, b = loop [] ll n in
  List.rev a, b

(** divide *)
let divide nh = divide' nh.current nh.history

(** equal *)
let equal l1 l2 =
  l1.filename = l2.filename && begin
    match l1.mark, l2.mark with
      | None, None -> l1.offset = l2.offset
      | (Some m1), (Some m2) -> (GtkText.Mark.get_name m1) = (GtkText.Mark.get_name m2)
      | _ -> false
  end

(** in_proximity *)
let in_proximity nh ~(view : GText.view) ~filename ~offset = function
  | {filename=fn; mark=(Some mark)} when filename = fn ->
    if not (GtkText.Mark.get_deleted mark) then begin
      let ofs = (view#buffer#get_iter_at_mark (`MARK mark))#offset in
      abs (offset - ofs) < proximity;
    end else false
  | _ -> false

(** destroy *)
let destroy loc =
  match loc.mark with
    | None -> ()
    | Some mark ->
      begin
        match GtkText.Mark.get_buffer mark with
          | None -> ()
          | Some buffer -> GtkText.Buffer.delete_mark buffer mark
      end;
      loc.mark <- None

(** trim *)
let trim nh =
  let len = List.length nh.history in
  let exceeding = len - nh.current - limit_hint in
  if exceeding > 0 && exceeding > nh.current then begin
    let keep, others = divide' (len - exceeding) nh.history in
    List.iter destroy others;
    nh.history <- keep;
  end;
  nh.history <- List.filter begin fun loc ->
    match loc.mark with
      | Some m -> not (GtkText.Mark.get_deleted m)
      | _ -> true
  end nh.history

(** add *)
let add nh ~kind ~(view : GText.view) ~filename ~offset =
  let mark = create_mark ~buffer:view#buffer ~offset in
  let loc = {kind=kind; filename=filename; mark=(Some mark); offset=offset} in
  begin
    try
      let top = List.hd nh.history in
      if in_proximity nh ~view ~filename ~offset top then begin
        destroy top;
        nh.history <- loc :: (List.tl nh.history)
      end else begin
        nh.history <- loc :: nh.history
      end;
    with Failure "hd" -> (nh.history <- [loc])
  end;
  nh.current <- 0(*;
  trim nh*)

(** last_edit_location *)
let last_edit_location nh =
  try Some (List.find (fun loc -> loc.kind = `EDIT) nh.history) with Not_found -> None

(** goto_last_edit_location *)
let goto_last_edit_location nh =
  nh.current <- 0;
  last_edit_location nh

(** goto *)
let goto nh ~location =
  let rec loop n = function
    | [] -> None
    | x :: y ->
      if equal x location then Some n else (loop (n + 1) y)
  in
  match loop 0 nh.history with
    | None -> ()
    | Some n -> nh.current <- n

(** get_history_backward *)
let get_history_backward nh =
  trim nh;
  try List.tl (snd (divide nh)) with Failure "tl" -> []

(** get_history_forward *)
let get_history_forward nh =
  trim nh;
  List.rev (fst (divide nh))

(** previous *)
let rec previous nh =
  trim nh;
  if nh.current < length nh - 1 then begin
    nh.current <- nh.current + 1;
    current_location nh
  end else None

(** next *)
and next nh =
  trim nh;
  if nh.current > 0 then begin
    nh.current <- nh.current - 1;
    current_location nh
  end else None

(** current_location *)
and current_location nh =
  try Some (List.nth nh.history nh.current) with Failure "nth" -> None

(** clear *)
let clear nh =
  List.iter destroy nh.history;
  nh.history <- [];
  nh.current <- 0

(** print *)
let print nh =
  printf "----------------------------------\n%!";
  printf "%d/%d %d/%d %s\n%!" (current_index nh) (length nh)
    (List.length (get_history_backward nh)) (List.length (get_history_forward nh))
    (match current_location nh with None -> "None"
    | Some loc -> string_of_location loc);
  let a, b = divide nh in
  List.iter (fun x -> printf "%s\n%!" (string_of_location x)) a;
  printf "---\n%!";
  List.iter (fun x -> printf "%s\n%!" (string_of_location x)) b







