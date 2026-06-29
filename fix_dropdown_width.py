import re

def main():
    with open('lib/screens/settings_screen.dart', 'r') as f:
        content = f.read()

    # We need to find all `trailing: DropdownButton` and wrap them in `SizedBox(width: 160, child: ... )`
    # We will iterate through the file character by character to handle nested brackets correctly.
    
    out = []
    i = 0
    while i < len(content):
        # Look for 'trailing: DropdownButton<'
        match = re.match(r'trailing:\s*DropdownButton<([^>]+)>\(', content[i:])
        if match:
            type_param = match.group(1)
            # Insert SizedBox and isExpanded: true
            prefix = f'trailing: SizedBox(width: 160, child: DropdownButton<{type_param}>(isExpanded: true, '
            out.append(prefix)
            
            i += len(match.group(0))
            
            # Now find the matching closing parenthesis for this DropdownButton
            bracket_count = 1
            start_idx = i
            while i < len(content) and bracket_count > 0:
                if content[i] == '(':
                    bracket_count += 1
                elif content[i] == ')':
                    bracket_count -= 1
                i += 1
            
            # We found the closing bracket for DropdownButton
            # content[start_idx:i-1] is the inside of the DropdownButton
            # content[i-1] is ')'
            out.append(content[start_idx:i-1])
            out.append('))') # close DropdownButton and SizedBox
            
        else:
            out.append(content[i])
            i += 1

    with open('lib/screens/settings_screen.dart', 'w') as f:
        f.write("".join(out))
        
if __name__ == '__main__':
    main()
