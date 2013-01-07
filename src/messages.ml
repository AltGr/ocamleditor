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

open GUtil

exception Cancel_process_termination

let hpaned = GPack.paned `HORIZONTAL ()
let vpaned = GPack.paned `VERTICAL ()

let table = Hashtbl.create 17

(** page *)
class virtual page =
object (self)
  val active = new GUtil.variable true
  val mutable parent : messages option = None
  val mutable close_tab_func = None
  method as_page = (self :> page)
  method set_parent p = parent <- Some p
  method present () = Gaux.may parent ~f:(fun messages -> messages#present self#coerce)
  method active = active
  method virtual parent_changed : messages -> unit
  method virtual coerce : GObj.widget
  method virtual misc : GObj.misc_ops
  method virtual destroy : unit -> unit
  method set_close_tab_func f = close_tab_func <- Some f
  method set_button b =
    Gaux.may close_tab_func ~f:(fun f -> b#connect#clicked ~callback:f);
end

(** messages *)
and messages ~(paned : GPack.paned) () =
  let notebook        = GPack.notebook ~scrollable:true ~tab_border:0 () in
  let remove_page     = new remove_page () in
  let visible_changed = new visible_changed () in
object (self)
  inherit GObj.widget notebook#as_widget
  inherit Messages_tab.drag_handler

  val mutable visible = true;
  val mutable empty_page = None

  initializer self#init()

  method private init () =
    paned#add2 notebook#coerce;
    notebook#set_tab_pos (if paned = hpaned then `BOTTOM(*`TOP*) else `BOTTOM);
    ignore (notebook#connect#remove ~callback:
      begin fun w ->
        if self#empty && self#visible then (self#set_visible false);
      end);
    self#set_visible false;
    (*  *)
    notebook#drag#dest_set Messages_tab.targets ~actions:[`MOVE ];
    ignore (notebook#drag#connect#data_received ~callback:self#data_received);

  method private empty =
    let len = List.length notebook#children in
    len = 0 || len = 1 && empty_page <> None

  method private set_page = notebook#set_page

  method private data_received context ~x ~y data ~info ~time =
    let failed () = context#finish ~success:false ~del:false ~time in
    if data#format = 8 then  begin
      try
        let oid = int_of_string data#data in
        let _, page = self#reparent oid in
        page#set_parent (self :> messages);
        notebook#goto_page (notebook#page_num page#coerce);
        context#finish ~success:true ~del:false ~time;
        page#parent_changed (self :> messages);
      with Not_found -> failed()
    end else (failed())

  method private remove_empty_page () =
    Gaux.may empty_page ~f:begin fun p ->
      notebook#set_show_tabs true;
      empty_page <- None;
      p#destroy()
    end;

  method reparent oid =
    let label_widget, page = Hashtbl.find table oid in
    let tab_label = new Messages_tab.widget ~with_spinner:false ~page () in
    ignore (tab_label#button#connect#clicked ~callback:page#destroy);
    label_widget#misc#reparent tab_label#hbox#coerce;
    page#misc#reparent self#coerce;
    self#set_page ~tab_label:tab_label#coerce page#coerce;
    self#remove_empty_page();
    label_widget, page

  method visible = visible

  method set_position = paned#set_position
  method position = paned#position

  method remove_all_tabs () =
    try
      List.iter (fun c -> (remove_page#call c); notebook#remove c; c#destroy()) notebook#children;
      self#set_visible false;
    with Exit -> ()

  method append_page ~label_widget ?with_spinner (page : page) =
    let tab_label = new Messages_tab.widget ~label_widget ?with_spinner ~page () in
    let _ = notebook#append_page ~tab_label:tab_label#coerce page#coerce in
    Hashtbl.add table page#misc#get_oid (label_widget, page);
    ignore (page#misc#connect#destroy ~callback:(fun () -> Hashtbl.remove table page#misc#get_oid));
    page#set_parent (self :> messages);
    self#remove_empty_page();

  method set_visible x =
    if x <> visible then begin
      if x then (paned#child2#misc#show ()) else (paned#child2#misc#hide ());
      visible <- not visible;
    end;
    if visible && List.length notebook#children = 0 then begin
      let page =
        let label = GMisc.label ~text:"No messages" () in
        object
          inherit page
          inherit GObj.widget label#as_widget
          method parent_changed _ = ()
        end
      in
      notebook#set_show_tabs false;
      ignore (self#append_page ~with_spinner:false ~label_widget:(GMisc.label())#coerce page#as_page);
      empty_page <- Some page
    end;
    visible_changed#call visible;

  method present page =
    if List.exists (fun c -> c#misc#get_oid = page#misc#get_oid) notebook#children then begin
      self#set_visible true;
      notebook#goto_page (notebook#page_num page);
    end

  method connect = new signals ~remove_page ~visible_changed
end

and signals ~remove_page ~visible_changed =
object (self)
  inherit ml_signals [remove_page#disconnect; visible_changed#disconnect ]
  method remove_page = remove_page#connect ~after
  method visible_changed = visible_changed#connect ~after
end

and remove_page () = object (self) inherit [GObj.widget] signal () end
and visible_changed () = object (self) inherit [bool] signal () end


let vmessages = new messages ~paned:vpaned ()
let hmessages = new messages ~paned:hpaned ()
























