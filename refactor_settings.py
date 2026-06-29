import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    content = f.read()

def extract_balanced(text, start_idx, open_char='(', close_char=')'):
    count = 0
    idx = start_idx
    while idx < len(text):
        if text[idx] == open_char:
            count += 1
        elif text[idx] == close_char:
            count -= 1
            if count == 0:
                return text[start_idx:idx+1], idx+1
        idx += 1
    return "", -1

new_content = ""
idx = 0
while idx < len(content):
    start = content.find("ListTile(", idx)
    if start == -1:
        new_content += content[idx:]
        break
        
    chunk_str, end = extract_balanced(content, start)
    
    if "DropdownButton<" in chunk_str:
        # Extract title
        title_start = chunk_str.find("title:")
        if title_start != -1:
            title_expr, _ = extract_balanced(chunk_str, chunk_str.find("Text(", title_start))
        else:
            title_expr = "Text('')"
            
        # Extract subtitle
        sub_start = chunk_str.find("subtitle:")
        if sub_start != -1:
            sub_expr, _ = extract_balanced(chunk_str, chunk_str.find("Text(", sub_start))
        else:
            sub_expr = None
            
        # Extract dropdown
        db_start = chunk_str.find("DropdownButton<")
        if db_start != -1:
            db_expr, _ = extract_balanced(chunk_str, chunk_str.find("(", db_start))
            db_type = chunk_str[db_start:chunk_str.find("(", db_start)]
            dropdown_full = db_type + db_expr
        else:
            dropdown_full = "Container()"
            
        new_code = f"""Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          {title_expr},"""
                          
        if sub_expr:
            new_code += f"""
                          const SizedBox(height: 4),
                          DefaultTextStyle(
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 13),
                            child: {sub_expr},
                          ),"""
                          
        new_code += f"""
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: {dropdown_full},
                            ),
                          ),
                        ],
                      ),
                    )"""
                    
        new_content += content[idx:start] + new_code
        idx = end
    else:
        new_content += content[idx:end]
        idx = end

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(new_content)
