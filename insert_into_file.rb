
def insert_into_file(destination, replacement, anchor, after)
  regexp = Regexp.new(Regexp.escape(anchor))
  if after
    string = '\0' + replacement
  else
    string = replacement + '\0'
  end
  content = File.binread(destination)
  content.gsub!(regexp, string)
  File.open(destination, "wb") { |file| file.write(content);file.flush }
end
