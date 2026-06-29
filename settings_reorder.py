import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    content = f.read()

# We will just write a python script to parse the list tiles out, but honestly it's simpler to just do it via exact string matching if we can.
