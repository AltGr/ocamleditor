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


let string_width s =
  let width = ref 0 in
  for i = 0 to String.length s - 1 do
    if s.[i] = '\t' then width := (!width / 8 + 1) * 8
    else incr width
  done;
  !width

let blanks                 = [13;10;32;9]
let not_blank c            = not (List.mem c blanks)
let whitespace_middot      = (*"."*) "\xC2\xB7"
let whitespace_tab         = "\xC2\xBB"
let whitespace_crlf        = "\xC2\xA4\xC2\xB6"
let whitespace_lf          = "\xC2\xB6"
let create_middot_string   = Miscellanea.Memo.fast ~f:(fun x ->
  String.concat "" (Miscellanea.Xlist.list_full whitespace_middot x))

