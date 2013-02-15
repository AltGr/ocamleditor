(*

  OCamlEditor
  Copyright (C) 2010-2013 Francesco Tovagliari

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

(** mk_ocp_indent_command *)
let mk_ocp_indent_command ?lines ?(config=Oe_config.ocp_indent_config) filename =
  let lines =
    match lines with
      | Some (n1, n2) -> sprintf " --lines %d-%d" n1 n2
      | _ -> ""
  in
  let config =
    match String.trim config with
      | "" -> ""
      | c -> " -c " ^ c
  in
  sprintf "ocp-indent --numeric%s%s %s" lines config filename;;

let forward_non_blank iter =
  let is_dirty = ref false in
  let rec f it =
    let ch = it#char in
    is_dirty := !is_dirty && ch = 9;
    if ch <> 32 && ch <> 9 && ch <> 13 then it
    else f it#forward_char
  in
  f iter, !is_dirty

(** indent *)
let indent ~view ?(all=false) () =
  let buffer = view#tbuffer in
  let indent () =
    match buffer#save_buffer() with
      | filename, _ ->
        let start, stop = if all then buffer#start_iter, buffer#end_iter else buffer#selection_bounds in
        let start, stop = if start#compare stop > 0 then stop, start else start, stop in
        let stop = if not (stop#equal start) then stop#backward_line#forward_to_line_end else stop in
        let lines = start#line + 1, stop#line + 1 in
        let cmd = mk_ocp_indent_command ~lines filename in
        let lines = Miscellanea.exec_lines cmd in
        buffer#undo#begin_block ~name:"ocp-indent";
        buffer#block_signal_handlers();
        let start_line = start#line in
        let start_line_index = start#line_index in
        List.iteri begin fun i spaces ->
          let spaces = int_of_string spaces in
          let start = buffer#get_iter (`LINE (start_line + i)) in
          let stop, is_dirty = forward_non_blank start in
          if stop#line_index - start#line_index <> spaces || is_dirty then begin
            buffer#delete ~start ~stop;
            let start = buffer#get_iter (`LINE (start_line + i)) in
            buffer#insert ?iter:(Some start) ?tag_names:None ?tags:None (String.make spaces ' ');
          end
        end lines;
        (*  *)
        if buffer#has_selection then begin
          let m = if (buffer#get_iter `INSERT)#compare (buffer#get_iter `SEL_BOUND) < 0
            then `INSERT else `SEL_BOUND in
          buffer#move_mark m ~where:(buffer#get_iter_at_char ?line:(Some start_line) start_line_index);
        end;
        buffer#unblock_signal_handlers();
        buffer#undo#end_block ();
        view#draw_current_line_background ?force:(Some true) (buffer#get_iter `INSERT);
        true
  in
  if not all && not buffer#has_selection then begin
    let ins = buffer#get_iter `INSERT in
    let iter = ins#set_line_index 0 in
    let stop = if iter#ends_line then iter else iter#forward_to_line_end in
    let line = iter#get_text ~stop in
    if String.trim line = "" then
      (if Oe_config.ocp_indent_empty_line = `INDENT then indent() else false)
    else if ins#ends_line then false else indent ()
  end else indent ()









