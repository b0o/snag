module {
  name:        "sway-ipc",
  version:     "0.1.0",
  description: "sway-ipc utility functions",
  authors:     ["Maddison Hellstrom <maddy@na.ai>"],
  license:     "GPL3",
};

import "util" as u;

# workspaces {{{

# takes a list of workspaces (as obtained by i3ipc's get_workspaces) and
# returns the focused workspace
def workspaces_get_focused:
  u::filter_arr_or_obj(.focused? == true; { "single": true, "recursive": false, "required": true })
;

# takes a list of workspaces (as obtained by i3ipc's get_workspaces) and
# returns all visible workspaces
def workspaces_get_visible:
  u::filter_arr_or_obj(.visible? == true; { "single": false, "recursive": false, "required": true })
;

# takes a list of workspaces (as obtained by i3ipc's get_workspaces) and
# returns the workspace whose id matches id
def workspaces_by_id(id):
  u::filter_arr_or_obj(.id? == id; { "single": true, "recursive": false, "required": true })
;

# takes a list of workspaces (as obtained by i3ipc's get_workspaces) and
# returns the workspace whose name matches name
def workspaces_by_name(name):
  u::filter_arr_or_obj(.name? == name; { "single": true, "recursive": false, "required": true })
;

# takes a workspace name and parses it based on i3-workspace-groups format
def parse_workspace_name:
  if type == "array" then
    map(parse_workspace_name)
  else
    if type == "string" then
      .
    elif type == "object" and .name? then
      .name
    else
      u::die("Error: unable to parse workspace name")
    end
    | . as $raw_name
    | sub("\u200b"; ""; "xg") # get rid of zero-width spaces
    | . as $global_name
    | split(":")
    | if length == 3 then
        .[3] = .[2] | .[2] = null
      else
        .
      end
    | map(if . == "" then null else . end)
    | { global_num:  .[0],
        group:       .[1],
        static_name: .[2],
        local_num:   .[3],
        global_name: $global_name,
        raw_name:    $raw_name
    }
  end
;

# }}}
# tree {{{

# takes a tree (as obtained by i3ipc's get_tree) and returns all visible nodes
def tree_get_visible:
  u::filter_arr_or_obj(.pid? and .visible? == true; { "single": false, "recursive": true, "required": true })
;

# takes a tree (as obtained by i3ipc's get_tree) and returns the focused node
def tree_get_focused:
  u::filter_arr_or_obj(.focused? == true; { "single": true, "recursive": true, "required": true })
;

# takes a tree (as obtained by i3ipc's get_workspaces) and returns the node
# matching id
def tree_by_id(id):
  u::filter_arr_or_obj(.id? == id; { "single": true, "recursive": true, "required": true })
;

# takes a tree (as obtained by i3ipc's get_workspaces) and returns all
# nodes whose name matches name
def tree_by_name(name):
  u::filter_arr_or_obj(.name? == name; { "single": false, "recursive": true, "required": true })
;

# }}}
# containers {{{

# takes a tree (as obtained by i3ipc's get_tree) and returns all visible container nodes
def containers_get_visible:
  u::filter_arr_or_obj((.type? == "con" or .type? == "floating_con") and .visible? == true; { "single": false, "recursive": true, "required": true })
;

# takes a tree (as obtained by i3ipc's get_tree) and returns the focused container node
def containers_get_focused:
  u::filter_arr_or_obj((.type? == "con" or .type? == "floating_con") and .focused? == true; { "single": true, "recursive": true, "required": true })
;

# takes a tree (as obtained by i3ipc's get_workspaces) and returns the
# container matching id
def containers_by_id(id):
  u::filter_arr_or_obj((.type? == "con" or .type? == "floating_con") and .id? == id; { "single": true, "recursive": true, "required": true })
;

# takes a tree (as obtained by i3ipc's get_workspaces) and returns all
# containers whose name matches name
def containers_by_name(name):
  u::filter_arr_or_obj((.type? == "con" or .type? == "floating_con") and name? == name; { "single": false, "recursive": true, "required": true })
;

# }}}
# outputs {{{

# takes a list of outputs (as obtained by i3ipc's get_outputs) and returns all
# active outputs
def outputs_get_active:
  u::filter_arr_or_obj(.active? == true and .dpms == true; { "single": false, "recursive": false, "required": true })
;

# takes a list of outputs (as obtained by i3ipc's get_outputs) and returns the
# focused output
def outputs_get_focused:
  u::filter_arr_or_obj(.focused? == true; { "single": true, "recursive": false, "required": true })
;

# takes a list of outputs (as obtained by i3ipc's get_outputs) and returns the
# output whose id matches id
def outputs_by_id(id):
  u::filter_arr_or_obj(.id? == id; { "single": true, "recursive": false, "required": true })
;

# takes a list of outputs (as obtained by i3ipc's get_outputs) and returns the
# outputs whose name matches name
def outputs_by_name(name):
  u::filter_arr_or_obj(.name? == name; { "single": true, "recursive": false, "required": true })
;

# }}}
# utility {{{

def fmt_rect:
  if type == "array" then
    map(fmt_rect)
  elif .rect? then
    if .window_rect? and (.window_rect.width // 0) > 0 and (.window_rect.height // 0) > 0 then
      if .deco_rect? and (.deco_rect.height // 0) > 0 then
        "\(.rect.x + .window_rect.x),\(.rect.y) \(.window_rect.width)x\(.window_rect.height)"
      else
        "\(.rect.x + .window_rect.x),\(.rect.y + .window_rect.y) \(.window_rect.width)x\(.window_rect.height)"
      end
    else
      "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"
    end
  else
    u::die("Error: unable to format rect")
  end
;

# }}}
