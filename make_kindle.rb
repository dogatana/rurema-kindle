require 'kindle'
require 'nokogiri'

module Toc
  def normalize(path)
    ret = []
    path.split('/').each do |p|
      case p
      when '.'
        next
      when '..'
        if ret.empty?
          ret << p
        else
          ret.pop
        end
      else
        ret << p
      end
    end
    ret.join('/')
  end
  
  def sub_toc(file)
    nav = []
    doc = Nokogiri::HTML.parse(open(file, 'r:utf-8', &:read))
    dir = File.dirname(file).sub(%r(^kindle/), '')
    skip = true
    doc.css('body').children.each do |node|
      if skip
        skip = false if node.name == 'h1'
        next
      end
      next if node.name == 'text'
      if node.name == 'ul'
        doc.css('li/a').each do |node|
          next if /^http/ =~ node['href']
          nav << Kindle::NavElement.new(node.text, "#{dir}/#{node['href']}")
        end
      end
      break
    end
    nav
  end
  
  def sub_toc_spec(file)
    nav = []
    doc = Nokogiri::HTML.parse(open(file, 'r:utf-8', &:read))
    dir = File.dirname(file).sub(%r(^kindle/), '')
    doc.css('li/a').each do |node|
      next if /^http/ =~ node['href']
      nav << Kindle::NavElement.new(node.text, normalize("#{dir}/#{node['href']}"))
    end
    nav
  end
  
  def sub_toc_lib(file)
    nav = []
    doc = Nokogiri::HTML.parse(open(file, 'r:utf-8', &:read))
    dir = File.dirname(file).sub(%r(^kindle/), '')
    doc.css('td/a').each do |node|
      next if /^http/ =~ node['href']
      nav << Kindle::NavElement.new(node.text, normalize("#{dir}/#{node['href']}"))
    end
    nav
  end
  
  def sub_toc_alllib(file)
    nav = []
    doc = Nokogiri::HTML.parse(open(file, 'r:utf-8', &:read))
    dir = File.dirname(file).sub(%r(^kindle/), '')
    doc.css('body/a').each do |node|
      next if /^http/ =~ node['href']
      nav << Kindle::NavElement.new(node.text, normalize("#{dir}/#{node['href']}"))
    end
    nav
  end
  
  def top_toc(file)
    nav = []
    doc = Nokogiri::HTML.parse(open(file, 'r:utf-8', &:read))
    dir = File.dirname(file).sub(%r(^kindle/), '')
    doc.css('li/a').each do |node|
      next if /^http/ =~ node['href']
      ref = normalize("#{dir}/#{node['href']}")
      nav << Kindle::NavElement.new(node.text, ref)
      sub = []
      case ref
      when /spec=2fcontrol.html$/, /spec=2fm17n.html$/
        sub = sub_toc_spec('kindle/' + ref) # ok
      #when /_builtin.html$/, /function\/index.html$/
      #  sub = sub_toc_lib('kindle/' + ref)
      when /library\/index.html$/
        sub = sub_toc_alllib('kindle/' + ref)
      else
        sub = sub_toc('kindle/' + ref)
      end
      nav[-1].children = sub unless sub.empty?
    end
    nav
  end

  module_function :top_toc
  module_function :sub_toc, :sub_toc_alllib, :sub_toc_lib, :sub_toc_spec
  module_function :normalize
end

nav_items = Toc.top_toc('kindle/doc/index.html')
Kindle::Nav.new('ja', nav_items).write('kindle/nav.xhtml')

spine_files = ['doc/index.html']
spine_files += nav_items.flatten.map { |x| x.file.sub(/#.*$/, '')}.uniq
spine_files += Dir.glob("kindle/class/**/*.html").map { |x| x.sub(/^kindle\//, '') }

items = []
ids   = []
spine_files.each do |file|
  item = Kindle::BookItem.new(file)
  items << item
  ids << item.id
end

files = []
%w(doc method library function).each do |dir|
  files += Dir.glob("kindle/#{dir}/**/*.html").map { |x| x.sub(/^kindle\//, '') }
end

(files - spine_files).each { |file| items << Kindle::BookItem.new(file) }

items << Kindle::BookItem.new('style.css')
items << Kindle::BookItem.new('88x31.png')

info = Kindle::BookInfo.new(
  'Ruby Reference Manual for Kindle',
  'Rubyリファレンスマニュアル刷新計画',
  'ja', 'cover.png', '00000000')

Kindle::Opf.new(info, items, ids).write('kindle/rurema.opf')
