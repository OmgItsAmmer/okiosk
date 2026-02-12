
import re

input_file = r'c:\Programming\Projects\02_GROWING\okiosk\supabase_functions.md'
output_file = r'c:\Programming\Projects\02_GROWING\okiosk\supabase_functions_clean.sql'

with open(input_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

functions = []
current_code = []

# Regex for the start of a row: | name | code
start_re = re.compile(r'^\|\s*([\w_]+)\s*\|\s*(.*)')

for line in lines[2:]:
    match = start_re.match(line)
    if match:
        # Save previous function if any
        if current_code:
            functions.append("".join(current_code).strip())
        
        # Start new function
        code_start = match.group(2)
        # If the code_start itself ends with the table terminator
        if code_start.strip() == '|':
            current_code = []
        elif code_start.rstrip().endswith(' |') or code_start.rstrip() == '|':
             # Handle single-line or weirdly capped lines
             current_code = [code_start.rstrip().rstrip('|').strip()]
             functions.append("".join(current_code).strip())
             current_code = []
        else:
            current_code = [code_start]
        continue
    
    # If we hit the "end of row" line which is just spaces and a |
    if line.strip() == '|' or (line.rstrip().endswith('|') and line.rstrip()[:-1].isspace()):
        if current_code:
            functions.append("".join(current_code).strip())
            current_code = []
        continue
        
    if current_code is not None:
        current_code.append(line)

# Final flush
if current_code:
    functions.append("".join(current_code).strip())

with open(output_file, 'w', encoding='utf-8') as f:
    # Filter out empty strings and join with double newlines
    f.write("\n\n".join([f for f in functions if f]))
