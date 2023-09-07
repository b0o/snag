module {
  name:        "util",
  version:     "0.1.0",
  description: "extra utility functions for jq",
};

# die prints msg to stderr and exits
def die(msg; code):
  msg + "\n" | halt_error(code)
;
def die(msg): die(msg; 1);

# dbg prints expr to stderr, and outputs its input unchanged
def dbg(expr):
  . as $in | expr | stderr | $in
;

# filter_arr_or_obj applies filter to either an object or an array;
# for an object, if filter matches, the object is returned (if single is false,
# the object is wrapped in an array)
# for an array, if filter matches, matching items are returned (if single is true,
# only the first match is returned)
def filter_arr_or_obj(filter; opts):
  .
  | ( opts | .single // false )    as $single
  | ( opts | .recursive // false ) as $recursive
  | ( opts | .required // false )  as $required
  | if $recursive and type == "object" then
      [..] | filter_arr_or_obj(filter; opts)
    else
      if type == "array" then
        map(select(filter))
        | if $single then
          .[0]
        else
          .
        end
      elif type == "object" then
        if (. | filter) then
          if $single then
            .
          else
            [ . ]
          end
        else
          empty
        end
      else
        die("Error: expected array or object")
      end
    end
  | if $required == true and ( . == null or . == [] ) then
      die("Error: no results")
    else
      .
    end
;
def filter_arr_or_obj(filter): filter_arr_or_obj(filter; {});

# to_entries_recursive is a recursive version of jq's to_entries function
def to_entries_recursive(p):
  if isempty(p) then
    {
      root: true,
      type: type,
      path: [],
      value: to_entries_recursive([])
    }
  elif type == "array" or type == "object" | not then . else
    to_entries | map([.value, p + [.key]] as [$val, $path] |
      {
        key: .key,
        type: $val | type,
        $path,
        value: $val | to_entries_recursive($path), # TODO: is this a tail-call?
      }
    )
  end
;
def to_entries_recursive: to_entries_recursive(empty);

# given an object or array, flatten_tree returns an object consisting of
# key:value pairs, where values are leaf nodes in the input object, and keys
# represent the path of the node in the input object hierarchy. If a node is an
# array, its children's keys are represe as their index proceeded by '__', e.g.
# {"items": ["foo", "bar", "qux"]} -> {"items__0": "foo", "items__1": "bar", "items__2": "qux"}
def flatten_tree:
  def _handle_node:
    if .type == "array" or .type == "object" | not then
      { (.path | join("__")): .value }
    else
      .value | map(_handle_node) | add
    end
  ;
  to_entries_recursive | _handle_node
;

# extended version of the @sh format string which also works on objects and
# arrays
def shell_fmt:
  if type == "object" or type == "array" then
    flatten_tree | to_entries | map("\(.key)=\(.value | shell_fmt)")
  elif . == null then
    ""
  else
    @sh
  end
;

# if input is an array, explode separates all elements
def explode:
  if type == "array" then
    .[]
  else
    .
  end
;

# similar to shell_fmt, but if result is an array it is exploded
def raw_shell_fmt:
   shell_fmt |
   if type == "array" then
     explode
   else
    .
   end
;
