import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

# Replace ensureInitialized
content = content.replace(
    'await DorarHadithFlutter.ensureInitialized();',
    """final dbDir = await getDatabasesPath();
  await DorarHadithFlutter.ensureInitialized(databaseDirectory: Directory(dbDir));"""
)

# Add imports if missing
if "import 'dart:io';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:io';\nimport 'package:sqflite/sqflite.dart';")

with open('lib/main.dart', 'w') as f:
    f.write(content)
