;+
;Procedure:
;  spd_ui_plugin_menu
;
;
;Purpose:
;  Builds GUI plugin menu.
;
;
;Calling Sequence:
;  spd_ui_plugin_menu, menu_id [,plugin_menu_items]
;
;
;Input:
;  menu_id: Widget ID of the parent menu into which plugin buttons will be placed.
;  plugin_menu_items: an array of structures containing the plugin menu items; loaded via pluginManager->getPluginMenus()
;
;
;Output:
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-03-31 16:53:14 -0700 (Tue, 31 Mar 2015) $
;$LastChangedRevision: 17214 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_plugin_menu.pro $
;
;-

pro spd_ui_plugin_menu, menu_id, plugin_menu_items

    compile_opt idl2, hidden

  

  if ~is_struct(plugin_menu_items) then begin
        ; no valid menu items
        dummy = widget_button(menu_id, value='None', sens=0)
        return
  endif
  nitems = n_elements(plugin_menu_items)
  
  if nitems lt 1 then begin
    dummy = widget_button(menu_id, value='None', sens=0)
;    dprint, dlevel=2, 'No plugins found in config file.'
    return
  endif
  
  
  ;----------------------------------------------------
  ; Loop over plugins
  ;----------------------------------------------------

  for i=0, nitems-1 do begin
    plugins = plugin_menu_items[i]
    name = strtrim(plugins.item,2)
    location = strtrim(strsplit(plugins.location, '|', /extract),2)
    procedure = strlowcase( strtrim(plugins.procedure,2) )
    
    ;warn user?
    if name eq '' then continue
    if procedure eq '' then continue

    ;create struct to store plugin name and data
    plugin = { name: name, $
               procedure: procedure, $
               data: ptr_new() $
               }

    ;----------------------------------------------------
    ; Loop over menu structure
    ;----------------------------------------------------
    
    node = menu_id
    
    for j=0, n_elements(location)-1 do begin
      
      ;ignore blank entries
      if location[j] eq '' then continue
      
      ;get children of current menu node
      children = widget_info(node, /all_children)

      ;if children exist then see if sub-node also exists
      if children[0] ne 0 then begin
        
        ;check unames
        unames = widget_info(children, /uname)
  
        idx = where(unames eq location[j], nidx)
        
        ;if match is found then select it and continue
        if nidx eq 1 then begin
          node = children[idx]
          continue
        endif
        
      endif
      
      ;if no matching child is found then create a new menu node
      new_node = widget_button(node, value=location[j], uname=location[j], /menu)
      
      ;select new node and continue
      node = new_node
      
    endfor
    
    ;----------------------------------------------------
    ; Add button to the current node
    ;----------------------------------------------------
    button = widget_button(node, value=name, uval=plugin, uname='GUI_PLUGIN')
    
  endfor
  
  if ~widget_valid(button) then begin
    dummy = widget_button(menu_id, value='None', sens=0)
    dprint, dlevel=2, 'GUI plugins not configured correctly.'
    return
  endif

end
