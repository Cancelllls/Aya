import 'dart:io';

void main() {
  print(Directory.current.path);
  Directory.current = '/tmp';
  print(Directory.current.path);
}
