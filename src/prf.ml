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

type t = {
  name : string;
  mutable calls : int;
  mutable time : float;
  mutable enabled : bool
}

let start_time = Unix.gettimeofday()

let funcs = ref []

let create enabled name =
  let cr = {name = name; calls = 0; time = 0.0; enabled = enabled} in
  funcs := cr :: !funcs;
  cr

(*
let prf_draw_markers                 = create true  "prf_draw_markers_view_expose"
let prf_error_indication_view_expose = create true  "prf_error_indication_view_expose"
let prf_paint_global_gutter          = create true  "prf_paint_global_gutter"
let prf_error_indication_tooltip     = create true  "prf_error_indication_tooltip"
let prf_error_indication_appy_tag    = create true  "prf_error_indication_appy_tag"
let prf_lexical_tag_insert           = create false "prf_lexical_tag_insert"
let prf_location_history_add         = create true  "prf_location_history_add"
let prf_paint_gutter          = create true  "prf_paint_gutter"
let prf_none_other_markers           = create true  "prf_none_other_markers"
let prf_draw_dot_leaders             = create true  "prf_draw_dot_leaders"
let prf_draw_white_spces             = create true  "prf_draw_white_spces"
*)

let prf_line_numbers                 = create true  "prf_line_numbers"
let prf_other_markers                = create true  "prf_other_markers"
let prf_scan_folding_points   = create true  "prf_scan_folding_points"
let prf_outline_select        = create true  "prf_outline_select"
let innermost_enclosing_delim = create true  "innermost_enclosing_delim"
let prf_delimiters_scan       = create true  "prf_delimiters_scan"
let prf_autosave              = create true  "prf_autosave"
let prf_compile_buffer        = create true  "prf_compile_buffer"

(*
                                                     Calls     Avg      Tot          calls/min
-----------------------------------------------------------------------------------------
prf_scan_folding_points .......................... :  1621   0.050    81.62   0.87%  2.88
prf_other_markers ................................ :  3450   0.008    26.87   0.29%  6.14
innermost_enclosing_delim ........................ :  1136   0.012    13.48   0.14%  2.02
prf_compile_buffer ............................... :   264   0.029     7.77   0.08%  0.47
prf_line_numbers ................................. :  2482   0.003     7.71   0.08%  4.42
prf_autosave ..................................... :  1867   0.000     0.64   0.01%  3.32
prf_outline_select ............................... :     0  -1.#IO     0.00   0.00%  0.00
prf_delimiters_scan .............................. :     0  -1.#IO     0.00   0.00%  0.00
-----------------------------------------------------------------------------------------

*)

let crono func f x =
  if not func.enabled then (f x) else
    let finally time =
      func.calls <- func.calls + 1;
      func.time <- func.time +. (Unix.gettimeofday() -. time);
    in
    let time = Unix.gettimeofday() in
    let result = try f x with e -> begin
      finally time;
      raise e
    end in
    finally time;
    result

let print () =
  let total = (Unix.gettimeofday()) -. start_time in
  printf "%50s   %5s%8s %8s %7s  %8s \n%!" "" "Calls" "Avg" "Tot" "" "calls/min";
  printf "\
-----------------------------------------------------------------------------------------\n%!";
  let perc = ref 0.0 in
  List.iter begin fun cr ->
    if cr.enabled then begin
      let pc = cr.time /. total *. 100. in
      perc := !perc +. pc;
      printf "%-50s : %5d  %6.3f  %7.2f  %5.2f%%  %4.2f\n%!"
        (Miscellanea.rpad (cr.name ^ " ") '.' 50) cr.calls (cr.time /. (float cr.calls)) cr.time pc
        (((float cr.calls) /. (total *. 60.)) *. 1000.)
    end
  end (List.rev (List.sort (fun a b -> Pervasives.compare a.time b.time) !funcs));
  printf "\
-----------------------------------------------------------------------------------------\n%!";
  printf "%-50s   %5d  %6.3f  %7.2f  %5.2f%%\n%!" (Miscellanea.rpad " " ' ' 50) 0 0.0 total !perc

