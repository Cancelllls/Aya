import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    text = f.read()

# We need to find `DropdownMenuItem(` and then inside it replace `child: Text(...)` with `child: Align(..., child: Text(...))`
# Since Python regex has trouble with nested parenthesis, I'll use a simple parser.

def add_align_to_dropdowns(text):
    res = ""
    idx = 0
    while True:
        pos = text.find('DropdownMenuItem', idx)
        if pos == -1:
            res += text[idx:]
            break
            
        res += text[idx:pos]
        idx = pos
        
        # Parse until the end of DropdownMenuItem
        stack = 0
        in_string = False
        escape = False
        start_idx = idx
        idx += len('DropdownMenuItem')
        
        # find first '('
        while idx < len(text) and text[idx] != '(':
            idx += 1
            
        if idx < len(text) and text[idx] == '(':
            stack = 1
            idx += 1
            
        while idx < len(text) and stack > 0:
            c = text[idx]
            if escape:
                escape = False
            elif c == '\\':
                escape = True
            elif c == "'" or c == '"':
                if not in_string:
                    in_string = c
                elif in_string == c:
                    in_string = False
            elif not in_string:
                if c == '(':
                    stack += 1
                elif c == ')':
                    stack -= 1
            idx += 1
            
        dropdown_item = text[start_idx:idx]
        
        # Now modify the dropdown_item
        if 'child: Align(' not in dropdown_item and 'child: Text(' in dropdown_item:
            # We need to replace `child: Text(` and add a `)` at the end of the text widget.
            child_pos = dropdown_item.find('child: Text(')
            
            # Find the end of Text(...)
            t_stack = 0
            t_idx = child_pos + len('child: Text')
            while t_idx < len(dropdown_item) and dropdown_item[t_idx] != '(':
                t_idx += 1
                
            if t_idx < len(dropdown_item) and dropdown_item[t_idx] == '(':
                t_stack = 1
                t_idx += 1
                
            in_t_str = False
            t_escape = False
            while t_idx < len(dropdown_item) and t_stack > 0:
                c = dropdown_item[t_idx]
                if t_escape:
                    t_escape = False
                elif c == '\\':
                    t_escape = True
                elif c == "'" or c == '"':
                    if not in_t_str:
                        in_t_str = c
                    elif in_t_str == c:
                        in_t_str = False
                elif not in_t_str:
                    if c == '(':
                        t_stack += 1
                    elif c == ')':
                        t_stack -= 1
                t_idx += 1
                
            # Now t_idx is the index right after `Text(...)`
            # We want to replace `child: Text(...)` with `child: Align(alignment: AlignmentDirectional.centerStart, child: Text(...))`
            modified = dropdown_item[:child_pos] + "child: Align(alignment: AlignmentDirectional.centerStart, " + dropdown_item[child_pos:t_idx] + ")" + dropdown_item[t_idx:]
            res += modified
        else:
            res += dropdown_item
            
    return res

new_text = add_align_to_dropdowns(text)

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(new_text)
    
print("Alignment fixed safely.")
