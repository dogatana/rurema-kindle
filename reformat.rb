require 'pathname'
require 'fileutils'


def abs2rel(base, dst)
  #puts "base: #{base}"
  #puts "dst: #{dst}"
  Pathname('/' + dst).relative_path_from(Pathname('/' + base)).to_s
end

def reformat(top, file)
  base_dir = File.dirname(file)

  html = open(file, 'r:utf-8', &:read)
  
  html.gsub(%r!(<a href="http://)(.*?\.html)(["#])!) { |ref|
    "<a href=\"#{abs2rel(base_dir, $2)}#$3"
  }.gsub(
    %r!<span class="permalink">.*?</span>!m, ''
  ).sub(
    %r!<a rel="license".*?</a>!m,
    "<img alt=\"Creative Commons License\" style=\"border-width:0\" src=\"#{
    abs2rel(base_dir, top + '/88x31.png')}\" />"
  )
end

def save(file, html)
  FileUtils.mkpath(File.dirname(file))
  open(file, 'w:utf-8').write(html)
end


exit unless ARGV.size == 1
top = ARGV[0].encode('utf-8').gsub(/\\/, '/')

Dir.glob("#{top}/**/*.html") do |file|
  new_html = reformat(top, file)
  save(file.sub(Regexp.new(top), 'kindle'), new_html)
end
