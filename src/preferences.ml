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

open Miscellanea
open Printf

type t = {
  mutable pref_timestamp                    : float;
  mutable pref_base_font                    : string;
  mutable pref_tab_pos                      : Gtk.Tags.position;
  mutable pref_check_updates                : bool;
  mutable pref_tab_label_type               : int;
  mutable pref_tab_vertical_text            : bool;
  mutable pref_bg_color                     : string * bool;
  mutable pref_bg_color_popup               : string;
  mutable pref_fg_color_popup               : string;
  mutable pref_tags                         : (string * text_properties) list;
  mutable pref_editor_tab_width             : int;
  mutable pref_editor_tab_spaces            : bool;
  mutable pref_editor_bak                   : bool;
  mutable pref_editor_wrap                  : bool;
  mutable pref_editor_trim_lines            : bool;
  mutable pref_editor_custom_templ_filename : string;
  mutable pref_editor_mark_occurrences      : string option;
  mutable pref_compl_font                   : string;
  mutable pref_compl_greek                  : bool;
  mutable pref_output_font                  : string;
  mutable pref_output_bg                    : string;
  mutable pref_output_fg_stdin              : string;
  mutable pref_output_fg_stdout             : string;
  mutable pref_output_fg_err                : string;
  mutable pref_output_fg_warn               : string;
  mutable pref_smart_keys_home              : int;
  mutable pref_smart_keys_end               : int;
  mutable pref_annot_type_tooltips_enabled  : bool;
  mutable pref_annot_type_tooltips_delay    : int;
  mutable pref_annot_type_tooltips_impl     : int;
  mutable pref_search_word_at_cursor        : bool;
  mutable pref_highlight_current_line       : bool;
  mutable pref_show_line_numbers            : bool;
  mutable pref_indent_lines                 : bool;
  mutable pref_right_margin_visible         : bool;
  mutable pref_right_margin                 : int;
  mutable pref_max_view_1_menubar           : bool;
  mutable pref_max_view_1_toolbar           : bool;
  mutable pref_max_view_1_tabbar            : bool;
  mutable pref_max_view_1_messages          : bool;
  mutable pref_max_view_1_fullscreen        : bool;
  mutable pref_max_view_2                   : bool;
  mutable pref_max_view_2_menubar           : bool;
  mutable pref_max_view_2_toolbar           : bool;
  mutable pref_max_view_2_tabbar            : bool;
  mutable pref_max_view_2_messages          : bool;
  mutable pref_max_view_2_fullscreen        : bool;
  mutable pref_max_view_fullscreen          : bool;
  mutable pref_ocamldoc_paragraph_bgcolor_1 : string option;
  mutable pref_ocamldoc_paragraph_bgcolor_2 : string option;
  mutable pref_code_folding_enabled         : bool;
  mutable pref_show_global_gutter           : bool;
  mutable pref_err_underline                : bool;
  mutable pref_err_tooltip                  : bool;
  mutable pref_err_gutter                   : bool;
  mutable pref_show_whitespace_chars        : bool;
  mutable pref_outline_show_types           : bool;
  mutable pref_odoc_font                    : string;
}
and text_properties = GDraw.color * Pango.Tags.weight * Pango.Tags.style * Pango.Tags.underline * Pango.Tags.scale

let pref_filename = Filename.concat Oe_config.ocamleditor_user_home "preferences.xml"

let default_tags = [
    "control";
    "define";
(*    "define2";*)
    "structure";
    "char";
    "infix";
    "label";
    "uident";
    "number";
    "custom";
    "lident";
    "symbol";
    "name_def";
    "method_name_def";
    "comment";
    "ocamldoc";
    "highlight";
    "highlight_current_line";
    "record_label";
  ]

let tag_labels = List.combine default_tags [
    "Control";
    "Definition";
(*    "define2";*)
    "Structure";
    "String";
    "Infix operator";
    "Label";
    "Capitalized identifier";
    "Number";
    "Exception occurrence";
    "Lowercase identifier";
    "Symbol";
    "Name definition";
    "Method name definition";
    "Comment";
    "ocamldoc";
    "Delimiter match highlight";
    "Line highlight";
    "Record label"
  ]

let default_colors : text_properties list = [
  (`NAME "blue"), `BOLD, `NORMAL, `NONE, `MEDIUM;
  (`NAME "forestgreen"), `BOLD, `NORMAL, `NONE, `MEDIUM;
(*    (`NAME "forestgreen"), `BOLD, `NORMAL, `NONE, `MEDIUM;*)
  (`NAME "purple"), `BOLD, `NORMAL, `NONE, `MEDIUM;
  (`NAME "firebrick3"), `NORMAL, `NORMAL, `NONE, `MEDIUM;
  (`NAME "indianred4"), `NORMAL, `NORMAL, `NONE, `MEDIUM;
  (`NAME "saddlebrown"), `BOLD, `NORMAL, `NONE, `MEDIUM;
  (`NAME "midnightblue"), `BOLD, `NORMAL, `NONE, `MEDIUM;
  (`NAME "blue"), `NORMAL, `NORMAL, `NONE, `MEDIUM;
  (`NAME "black"), `BOLD, `NORMAL, `NONE, `MEDIUM;
  (`NAME "black"), `NORMAL, `NORMAL, `NONE, `MEDIUM;
  (`NAME "black"), `NORMAL, `NORMAL, `NONE, `MEDIUM;
  (`NAME "black"), `NORMAL, `NORMAL, `NONE, `MEDIUM;
  (`NAME "black"), `NORMAL, `NORMAL, `NONE, `MEDIUM;
  (`NAME "deeppink3"), `NORMAL, `ITALIC, `NONE, `MEDIUM;
  (`NAME "deeppink3"), `NORMAL, `ITALIC, `NONE, `MEDIUM;
  (`NAME "#FFFF00"), `NORMAL, `NORMAL, `LOW, `MEDIUM;
  (`NAME "#F9F9CA"), `NORMAL, `NORMAL, `NONE, `MEDIUM;(* #E8F2FF *) (* #F7F7D7 *)
  (`NAME "#474747"), `NORMAL, `ITALIC, `NONE, `MEDIUM;
]

let defaults = {
  pref_timestamp                    = (Unix.gettimeofday());
  pref_base_font                    = "monospace 9";
  pref_tab_pos                      = `TOP;
  pref_check_updates                = false;
  pref_tab_vertical_text            = false;
  pref_tab_label_type               = 1;
  pref_bg_color                     = ("#ffffff", false);
  pref_bg_color_popup               = "#F0F4FF";  (* f1edbd F0F4FF #F7F7F7 #E8ECFF #EAEAFF *)
  pref_fg_color_popup               = "#444444";
  pref_tags                         = List.combine default_tags default_colors;
  pref_editor_tab_width             = 2;
  pref_editor_tab_spaces            = true;
  pref_editor_bak                   = true;
  pref_editor_wrap                  = false;
  pref_editor_trim_lines            = false;
  pref_editor_custom_templ_filename = "";
  pref_editor_mark_occurrences      = Some "#90ff90";
  pref_compl_font                   = "Sans 9";
  pref_compl_greek                  = true;
  pref_output_font                  = "monospace 8";
  pref_output_bg                    = "#FFFFFF";
  pref_output_fg_stdin              = "#0000FF";
  pref_output_fg_stdout             = "#000000";
  pref_output_fg_err                = "#FF0000";
  pref_output_fg_warn               = "darkorange";
  pref_smart_keys_home              = 0;
  pref_smart_keys_end               = 0;
  pref_annot_type_tooltips_enabled  = false;
  pref_annot_type_tooltips_delay    = 0;
  pref_annot_type_tooltips_impl     = 0;
  pref_search_word_at_cursor        = true;
  pref_highlight_current_line       = true;
  pref_show_line_numbers            = true;
  pref_indent_lines                 = true;
  pref_right_margin_visible         = false;
  pref_right_margin                 = 80;
  pref_max_view_1_menubar           = true;
  pref_max_view_1_toolbar           = false;
  pref_max_view_1_tabbar            = false;
  pref_max_view_1_messages          = false;
  pref_max_view_1_fullscreen        = false;
  pref_max_view_2                   = true;
  pref_max_view_2_menubar           = true;
  pref_max_view_2_toolbar           = true;
  pref_max_view_2_tabbar            = true;
  pref_max_view_2_messages          = true;
  pref_max_view_2_fullscreen        = true;
  pref_max_view_fullscreen          = false;
  pref_ocamldoc_paragraph_bgcolor_1 = Some "#FAF7FA" (*"#F5F0FF"*);
  pref_ocamldoc_paragraph_bgcolor_2 = Some "#FAF7FA" (*"#F8F5FF"*);
  pref_code_folding_enabled         = true;
  pref_show_global_gutter           = true;
  pref_err_underline                = true;
  pref_err_tooltip                  = true;
  pref_err_gutter                   = true;
  pref_show_whitespace_chars        = false;
  pref_outline_show_types           = false;
  pref_odoc_font                    = "Serif 9";
}

let create_defaults () = {
  pref_timestamp                    = (Unix.gettimeofday());
  pref_base_font                    = defaults.pref_base_font;
  pref_tab_pos                      = defaults.pref_tab_pos;
  pref_check_updates                = defaults.pref_check_updates;
  pref_tab_vertical_text            = defaults.pref_tab_vertical_text;
  pref_tab_label_type               = defaults.pref_tab_label_type;
  pref_bg_color                     = defaults.pref_bg_color;
  pref_bg_color_popup               = defaults.pref_bg_color_popup;
  pref_fg_color_popup               = defaults.pref_fg_color_popup;
  pref_tags                         = defaults.pref_tags;
  pref_editor_tab_width             = defaults.pref_editor_tab_width;
  pref_editor_tab_spaces            = defaults.pref_editor_tab_spaces;
  pref_editor_bak                   = defaults.pref_editor_bak;
  pref_editor_wrap                  = defaults.pref_editor_wrap;
  pref_editor_trim_lines            = defaults.pref_editor_trim_lines;
  pref_editor_custom_templ_filename = defaults.pref_editor_custom_templ_filename;
  pref_editor_mark_occurrences      = defaults.pref_editor_mark_occurrences;
  pref_compl_font                   = defaults.pref_compl_font;
  pref_compl_greek                  = defaults.pref_compl_greek;
  pref_output_font                  = defaults.pref_output_font;
  pref_output_bg                    = defaults.pref_output_bg;
  pref_output_fg_stdin              = defaults.pref_output_fg_stdin;
  pref_output_fg_stdout             = defaults.pref_output_fg_stdout;
  pref_output_fg_err                = defaults.pref_output_fg_err;
  pref_output_fg_warn               = defaults.pref_output_fg_warn;
  pref_smart_keys_home              = defaults.pref_smart_keys_home;
  pref_smart_keys_end               = defaults.pref_smart_keys_end;
  pref_annot_type_tooltips_enabled  = defaults.pref_annot_type_tooltips_enabled;
  pref_annot_type_tooltips_delay    = defaults.pref_annot_type_tooltips_delay;
  pref_annot_type_tooltips_impl     = defaults.pref_annot_type_tooltips_impl;
  pref_search_word_at_cursor        = defaults.pref_search_word_at_cursor;
  pref_highlight_current_line       = defaults.pref_highlight_current_line;
  pref_show_line_numbers            = defaults.pref_show_line_numbers;
  pref_indent_lines                 = defaults.pref_indent_lines;
  pref_right_margin_visible         = defaults.pref_right_margin_visible;
  pref_right_margin                 = defaults.pref_right_margin;
  pref_max_view_1_menubar           = defaults.pref_max_view_1_menubar;
  pref_max_view_1_toolbar           = defaults.pref_max_view_1_toolbar;
  pref_max_view_1_tabbar            = defaults.pref_max_view_1_tabbar;
  pref_max_view_1_messages          = defaults.pref_max_view_1_messages;
  pref_max_view_1_fullscreen        = defaults.pref_max_view_1_fullscreen;
  pref_max_view_2                   = defaults.pref_max_view_2;
  pref_max_view_2_menubar           = defaults.pref_max_view_2_menubar;
  pref_max_view_2_toolbar           = defaults.pref_max_view_2_toolbar;
  pref_max_view_2_tabbar            = defaults.pref_max_view_2_tabbar;
  pref_max_view_2_messages          = defaults.pref_max_view_2_messages;
  pref_max_view_2_fullscreen        = defaults.pref_max_view_2_fullscreen;
  pref_max_view_fullscreen          = defaults.pref_max_view_fullscreen;
  pref_ocamldoc_paragraph_bgcolor_1 = defaults.pref_ocamldoc_paragraph_bgcolor_1;
  pref_ocamldoc_paragraph_bgcolor_2 = defaults.pref_ocamldoc_paragraph_bgcolor_2;
  pref_code_folding_enabled         = defaults.pref_code_folding_enabled;
  pref_show_global_gutter           = defaults.pref_show_global_gutter;
  pref_err_underline                = defaults.pref_err_underline;
  pref_err_tooltip                  = defaults.pref_err_tooltip;
  pref_err_gutter                   = defaults.pref_err_gutter;
  pref_show_whitespace_chars        = defaults.pref_show_whitespace_chars;
  pref_outline_show_types           = defaults.pref_outline_show_types;
  pref_odoc_font                    = defaults.pref_odoc_font;
}

let preferences = new GUtil.variable (create_defaults ())

let string_of_pos = function
  | `TOP -> "TOP"
  | `BOTTOM -> "BOTTOM"
  | `LEFT -> "LEFT"
  | `RIGHT -> "RIGHT"

let string_of_weight = function
  | `NORMAL -> "NORMAL"
  | `BOLD -> "BOLD"
  | _ -> assert false

let string_of_style = function
  | `NORMAL -> "NORMAL"
  | `ITALIC -> "ITALIC"
  | _ -> assert false

let string_of_underline = function
  | `NONE -> "NONE"
  | `LOW -> "LOW"
  | `DOUBLE -> "DOUBLE"
  | `SINGLE -> "SINGLE"

let string_of_color = function
  | `NAME name -> name
  | _ -> assert false

let pos_of_string = function
  | "TOP" -> `TOP
  | "BOTTOM" -> `BOTTOM
  | "LEFT" -> `LEFT
  | "RIGHT" -> `RIGHT
  | _ -> assert false

let weight_of_string = function
  | "NORMAL" -> `NORMAL
  | "BOLD" -> `BOLD
  | _ -> assert false

let style_of_string = function
  | "NORMAL" -> `NORMAL
  | "ITALIC" -> `ITALIC
  | _ -> assert false

let underline_of_string = function
  | "NONE" -> `NONE
  | "LOW" -> `LOW
  | "DOUBLE" -> `DOUBLE
  | "SINGLE" -> `SINGLE
  | _ -> assert false

let scale_of_string = function
  | "SMALL" -> `SMALL
  | "MEDIUM" -> `MEDIUM
  | "LARGE" -> `LARGE
  | _ -> assert false

let color_of_string name = `NAME name

let to_xml pref =
  let xml =
    Xml.Element ("preferences", [], [
      Xml.Element ("pref_base_font", [], [Xml.PCData pref.pref_base_font]);
      Xml.Element ("pref_check_updates", [], [Xml.PCData (string_of_bool pref.pref_check_updates)]);
      Xml.Element ("pref_tab_pos", [], [Xml.PCData (string_of_pos pref.pref_tab_pos)]);
      Xml.Element ("pref_tab_vertical_text", [], [Xml.PCData (string_of_bool pref.pref_tab_vertical_text)]);
      Xml.Element ("pref_tab_label_type", [], [Xml.PCData (string_of_int pref.pref_tab_label_type)]);
      Xml.Element ("pref_bg_color", [], [Xml.PCData (fst pref.pref_bg_color)]);
      Xml.Element ("pref_bg_color_theme", [], [Xml.PCData (string_of_bool (snd pref.pref_bg_color))]);
      Xml.Element ("pref_bg_color_popup", [], [Xml.PCData pref.pref_bg_color_popup]);
      Xml.Element ("pref_fg_color_popup", [], [Xml.PCData pref.pref_fg_color_popup]);
      Xml.Element ("pref_tags", [],
        List.map begin fun (id, (color, weight, style, uline, scale)) ->
          Xml.Element ("tag", [
            ("name", id);
            ("color", string_of_color color);
            ("weight", string_of_weight weight);
            ("style", string_of_style style);
            ("underline", string_of_underline uline);
            ("scale", "MEDIUM");
          ], []);
        end pref.pref_tags
      );
      Xml.Element ("pref_editor_tab_width", [], [Xml.PCData (string_of_int pref.pref_editor_tab_width)]);
      Xml.Element ("pref_editor_tab_spaces", [], [Xml.PCData (string_of_bool pref.pref_editor_tab_spaces)]);
      Xml.Element ("pref_editor_wrap", [], [Xml.PCData (string_of_bool pref.pref_editor_wrap)]);
      Xml.Element ("pref_editor_trim_lines", [], [Xml.PCData (string_of_bool pref.pref_editor_trim_lines)]);
      Xml.Element ("pref_editor_bak", [], [Xml.PCData (string_of_bool pref.pref_editor_bak)]);
      Xml.Element ("pref_editor_mark_occurrences", [], [Xml.PCData (match pref.pref_editor_mark_occurrences with Some x -> x | _ -> "")]);
      Xml.Element ("pref_editor_custom_templ_filename", [], [Xml.PCData (pref.pref_editor_custom_templ_filename)]);
      Xml.Element ("pref_compl_font", [], [Xml.PCData pref.pref_compl_font]);
      Xml.Element ("pref_compl_greek", [], [Xml.PCData (string_of_bool pref.pref_compl_greek)]);
      Xml.Element ("pref_output_font", [], [Xml.PCData pref.pref_output_font]);
      Xml.Element ("pref_output_bg", [], [Xml.PCData pref.pref_output_bg]);
      Xml.Element ("pref_output_fg_stdin", [], [Xml.PCData pref.pref_output_fg_stdin]);
      Xml.Element ("pref_output_fg_stdout", [], [Xml.PCData pref.pref_output_fg_stdout]);
      Xml.Element ("pref_output_fg_err", [], [Xml.PCData pref.pref_output_fg_err]);
      Xml.Element ("pref_output_fg_warn", [], [Xml.PCData pref.pref_output_fg_warn]);
      Xml.Element ("pref_smart_keys_home", [], [Xml.PCData (string_of_int pref.pref_smart_keys_home)]);
      Xml.Element ("pref_smart_keys_end", [], [Xml.PCData (string_of_int pref.pref_smart_keys_end)]);
      Xml.Element ("pref_annot_type_tooltips_enabled", [], [Xml.PCData (string_of_bool pref.pref_annot_type_tooltips_enabled)]);
      Xml.Element ("pref_annot_type_tooltips_delay", [], [Xml.PCData (string_of_int pref.pref_annot_type_tooltips_delay)]);
      Xml.Element ("pref_annot_type_tooltips_impl", [], [Xml.PCData (string_of_int pref.pref_annot_type_tooltips_impl)]);
      Xml.Element ("pref_search_word_at_cursor", [], [Xml.PCData (string_of_bool pref. pref_search_word_at_cursor)]);
      Xml.Element ("pref_highlight_current_line", [], [Xml.PCData (string_of_bool pref.pref_highlight_current_line)]);
      Xml.Element ("pref_show_line_numbers", [], [Xml.PCData (string_of_bool pref.pref_show_line_numbers)]);
      Xml.Element ("pref_indent_lines", [], [Xml.PCData (string_of_bool pref.pref_indent_lines)]);
      Xml.Element ("pref_right_margin_visible", [], [Xml.PCData (string_of_bool pref.pref_right_margin_visible)]);
      Xml.Element ("pref_right_margin", [], [Xml.PCData (string_of_int pref.pref_right_margin)]);
      Xml.Element ("pref_max_view_1_menubar", [], [Xml.PCData (string_of_bool pref.pref_max_view_1_menubar)]);
      Xml.Element ("pref_max_view_1_toolbar", [], [Xml.PCData (string_of_bool pref.pref_max_view_1_toolbar)]);
      Xml.Element ("pref_max_view_1_tabbar", [], [Xml.PCData (string_of_bool pref.pref_max_view_1_tabbar)]);
      Xml.Element ("pref_max_view_1_messages", [], [Xml.PCData (string_of_bool pref.pref_max_view_1_messages)]);
      Xml.Element ("pref_max_view_1_fullscreen", [], [Xml.PCData (string_of_bool pref.pref_max_view_1_fullscreen)]);
      Xml.Element ("pref_max_view_2", [], [Xml.PCData (string_of_bool pref.pref_max_view_2)]);
      Xml.Element ("pref_max_view_2_menubar", [], [Xml.PCData (string_of_bool pref.pref_max_view_2_menubar)]);
      Xml.Element ("pref_max_view_2_toolbar", [], [Xml.PCData (string_of_bool pref.pref_max_view_2_toolbar)]);
      Xml.Element ("pref_max_view_2_tabbar", [], [Xml.PCData (string_of_bool pref.pref_max_view_2_tabbar)]);
      Xml.Element ("pref_max_view_2_messages", [], [Xml.PCData (string_of_bool pref.pref_max_view_2_messages)]);
      Xml.Element ("pref_max_view_2_fullscreen", [], [Xml.PCData (string_of_bool pref.pref_max_view_2_fullscreen)]);
      Xml.Element ("pref_max_view_fullscreen", [], [Xml.PCData (string_of_bool pref.pref_max_view_fullscreen)]);
      Xml.Element ("pref_ocamldoc_paragraph_bgcolor_1", [], [Xml.PCData (match pref.pref_ocamldoc_paragraph_bgcolor_1 with None -> "" | Some x -> x)]);
      Xml.Element ("pref_ocamldoc_paragraph_bgcolor_2", [], [Xml.PCData (match pref.pref_ocamldoc_paragraph_bgcolor_2 with None -> "" | Some x -> x)]);
      Xml.Element ("pref_code_folding_enabled", [], [Xml.PCData (string_of_bool pref.pref_code_folding_enabled)]);
      Xml.Element ("pref_show_global_gutter", [], [Xml.PCData (string_of_bool pref.pref_show_global_gutter)]);
      Xml.Element ("pref_err_underline", [], [Xml.PCData (string_of_bool pref.pref_err_underline)]);
      Xml.Element ("pref_err_tooltip", [], [Xml.PCData (string_of_bool pref.pref_err_tooltip)]);
      Xml.Element ("pref_err_gutter", [], [Xml.PCData (string_of_bool pref.pref_err_gutter)]);
      Xml.Element ("pref_show_whitespace_chars", [], [Xml.PCData (string_of_bool pref.pref_show_whitespace_chars)]);
      Xml.Element ("pref_outline_show_types", [], [Xml.PCData (string_of_bool pref.pref_outline_show_types)]);
      Xml.Element ("pref_odoc_font", [], [Xml.PCData (pref.pref_odoc_font)]);

    ])
  in
  let xml = Xml.to_string_fmt xml in
  "<!-- OCamlEditor XML Preferences -->\n" ^ xml
;;

(** from_file *)
let from_file filename =
  try
    let xml = Xml.parse_file filename in
    let pref = create_defaults () in
    let value xml =
      match Xml.children xml with
        | [] -> ""
        | x :: [] -> Xml.pcdata x
        | _ -> assert false
    in
    let bg_color = ref "" in
    let bg_color_theme = ref false in
    Xml.iter begin fun node ->
      match Xml.tag node with
        | "pref_check_updates" -> pref.pref_check_updates <- bool_of_string (value node)
        | "pref_base_font" -> pref.pref_base_font <- value node
        | "pref_tab_pos" -> pref.pref_tab_pos <- pos_of_string (value node)
        | "pref_tab_vertical_text" -> pref.pref_tab_vertical_text <- bool_of_string (value node)
        | "pref_tab_label_type" -> pref.pref_tab_label_type <- int_of_string (value node)
        | "pref_bg_color" -> bg_color := value node
        | "pref_bg_color_theme" -> bg_color_theme := (bool_of_string (value node))
        | "pref_bg_color_popup" -> pref.pref_bg_color_popup <- value node
        | "pref_fg_color_popup" -> pref.pref_fg_color_popup <- value node
        | "pref_tags" ->
          pref.pref_tags <- [];
          Xml.iter begin fun tp ->
            pref.pref_tags <- (
              (Xml.attrib tp "name"), (
              (color_of_string (Xml.attrib tp "color")),
              (weight_of_string (Xml.attrib tp "weight")),
              (style_of_string (Xml.attrib tp "style")),
              (underline_of_string (Xml.attrib tp "underline")),
              (try scale_of_string (Xml.attrib tp "scale") with Xml.No_attribute _ -> `MEDIUM)
            )) :: pref.pref_tags
          end node;
          List.iter begin fun (tag, _) ->
            if try List.assoc tag pref.pref_tags; false with Not_found -> true then begin
              let defaults = List.assoc tag defaults.pref_tags in
              pref.pref_tags <- (tag, defaults) :: pref.pref_tags
            end
          end defaults.pref_tags
        | "pref_editor_tab_width" -> pref.pref_editor_tab_width <- int_of_string (value node)
        | "pref_editor_tab_spaces" -> pref.pref_editor_tab_spaces <- bool_of_string (value node)
        | "pref_editor_wrap" -> pref.pref_editor_wrap <- bool_of_string (value node)
        | "pref_editor_trim_lines" -> pref.pref_editor_trim_lines <- bool_of_string (value node)
        | "pref_editor_bak" -> pref.pref_editor_bak <- bool_of_string (value node)
        | "pref_editor_custom_templ_filename" -> pref.pref_editor_custom_templ_filename <- value node
        | "pref_editor_mark_occurrences" -> pref.pref_editor_mark_occurrences <- (let x = value node in if x = "" then None else Some x)
        | "pref_compl_font" -> pref.pref_compl_font <- value node
        | "pref_compl_greek" -> pref.pref_compl_greek <- bool_of_string (value node)
        | "pref_output_font" -> pref.pref_output_font <- value node
        | "pref_output_bg" -> pref.pref_output_bg <- value node
        | "pref_output_fg_stdin" -> pref.pref_output_fg_stdin <- value node
        | "pref_output_fg_stdout" -> pref.pref_output_fg_stdout <- value node
        | "pref_output_fg_err" -> pref.pref_output_fg_err <- value node
        | "pref_output_fg_warn" -> pref.pref_output_fg_warn <- value node
        | "pref_smart_keys_home" -> pref.pref_smart_keys_home <- int_of_string (value node)
        | "pref_smart_keys_end" -> pref.pref_smart_keys_end <- int_of_string (value node)
        | "pref_annot_type_tooltips_enabled" -> pref.pref_annot_type_tooltips_enabled <- bool_of_string (value node)
        | "pref_annot_type_tooltips_delay" -> pref.pref_annot_type_tooltips_delay <- int_of_string (value node)
        | "pref_annot_type_tooltips_impl" -> pref.pref_annot_type_tooltips_impl <- int_of_string (value node)
        | "pref_search_word_at_cursor" -> pref.pref_search_word_at_cursor <- bool_of_string (value node)
        | "pref_highlight_current_line" -> pref.pref_highlight_current_line <- bool_of_string (value node)
        | "pref_show_line_numbers" -> pref.pref_show_line_numbers <- bool_of_string (value node)
        | "pref_indent_lines" -> pref.pref_indent_lines <- bool_of_string (value node)
        | "pref_right_margin_visible" -> pref.pref_right_margin_visible <- bool_of_string (value node)
        | "pref_right_margin" -> pref.pref_right_margin <- int_of_string (value node)
        | "pref_max_view_1_menubar" -> pref.pref_max_view_1_menubar <- bool_of_string (value node)
        | "pref_max_view_1_toolbar" -> pref.pref_max_view_1_toolbar <- bool_of_string (value node)
        | "pref_max_view_1_tabbar" -> pref.pref_max_view_1_tabbar <- bool_of_string (value node)
        | "pref_max_view_1_messages" -> pref.pref_max_view_1_messages <- bool_of_string (value node)
        | "pref_max_view_1_fullscreen" -> pref.pref_max_view_1_fullscreen <- bool_of_string (value node)
        | "pref_max_view_2" -> pref.pref_max_view_2 <- bool_of_string (value node)
        | "pref_max_view_2_menubar" -> pref.pref_max_view_2_menubar <- bool_of_string (value node)
        | "pref_max_view_2_toolbar" -> pref.pref_max_view_2_toolbar <- bool_of_string (value node)
        | "pref_max_view_2_tabbar" -> pref.pref_max_view_2_tabbar <- bool_of_string (value node)
        | "pref_max_view_2_messages" -> pref.pref_max_view_2_messages <- bool_of_string (value node)
        | "pref_max_view_2_fullscreen" -> pref.pref_max_view_2_fullscreen <- bool_of_string (value node)
        | "pref_max_view_fullscreen" -> pref.pref_max_view_fullscreen <- bool_of_string (value node)
        | "pref_ocamldoc_paragraph_bgcolor" ->
          pref.pref_ocamldoc_paragraph_bgcolor_1 <- Some (value node);
          pref.pref_ocamldoc_paragraph_bgcolor_2 <- defaults.pref_ocamldoc_paragraph_bgcolor_2;
        | "pref_ocamldoc_paragraph_bgcolor_1" -> pref.pref_ocamldoc_paragraph_bgcolor_1 <- (match value node with "" -> None | x -> Some x)
        | "pref_ocamldoc_paragraph_bgcolor_2" -> pref.pref_ocamldoc_paragraph_bgcolor_2 <- (match value node with "" -> None | x -> Some x)
        | "pref_code_folding_enabled" -> pref.pref_code_folding_enabled <- bool_of_string (value node)
        | "pref_show_global_gutter" -> pref.pref_show_global_gutter <- bool_of_string (value node)
        | "pref_err_underline" -> pref.pref_err_underline <- bool_of_string (value node)
        | "pref_err_tooltip" -> pref.pref_err_tooltip <- bool_of_string (value node)
        | "pref_err_gutter" -> pref.pref_err_gutter <- bool_of_string (value node)
        | "pref_show_whitespace_chars" -> pref.pref_show_whitespace_chars <- bool_of_string (value node)
        | "pref_outline_show_types" -> pref.pref_outline_show_types <- bool_of_string (value node)
        | "pref_odoc_font" -> pref.pref_odoc_font <- value node

       | _ -> ()
    end xml;
    pref.pref_bg_color <- (!bg_color, !bg_color_theme);
    pref
  with Xml.File_not_found _ -> create_defaults()
;;

(** save *)
let save () =
  let xml = to_xml preferences#get in
  let chan = open_out_bin pref_filename in
  lazy (output_string chan xml) @$ lazy (close_out chan);
  preferences#set {preferences#get with pref_timestamp = Unix.gettimeofday()}

(** load *)
let load () =
  let pref = try from_file pref_filename with ex -> begin
    Printf.eprintf "File \"preferences.ml\": %s\n%s\n%!" (Printexc.to_string ex) (Printexc.get_backtrace());
    create_defaults ()
  end in
  preferences#set pref

(** tag_color *)
let tag_color tagname =
  match List.assoc tagname preferences#get.pref_tags with
    | color, _, _, _, _ -> GDraw.color color

(** tag_underline *)
let tag_underline tagname =
  match List.assoc tagname preferences#get.pref_tags with
    | _, _, _, underline, _ -> underline

(** reset_defaults *)
let reset_defaults () =
  if Sys.file_exists pref_filename then Sys.remove pref_filename;
  preferences#set (create_defaults());
  save()

let _ = begin
  load();
end
