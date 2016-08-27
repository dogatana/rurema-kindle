INDEX = 'docs.ruby-lang.org/ja/2.3.0/doc/index.html'
CCLOGO = "kindle/88x31.png"

# directory 'kindle' がうまく動かせられない。。
mkdir 'kindle' unless File.exist?('kindle')

task :default do
  puts <<-EOF
execute following steps to create Kindle file
1) rake download
2) rake setup
3) rake mobi
4) copy kindle/rurema.mobi to your kindle device
  EOF
end

#task :download => [INDEX, CCLOGO]
task :download => CCLOGO

file INDEX do
  puts 'wget -r -l3 -p -k -w1 --random-wait http://docs.ruby-lang.org/ja/2.3.0/doc/index.html'
end

file CCLOGO do
  puts 'wget -O 88x31.png http://i.creativecommons.org/l/by/3.0/88x31.png'
end

task :setup do
  sh 'ruby reformat.rb docs.ruby-lang.org/ja/2.3.0'
  sh 'ruby make_kindle.rb'
  cp 'cover.png', 'kindle'
  cp 'style.css', 'kindle'
  cp '88x31.png', 'kindle'
end

task :kindle do
  sh 'ruby make_kindle.rb'
end

task :mobi do
  chdir 'kindle' do
    sh 'kindlegen rurema.opf'
    mv 'rurema.mobi','..'
  end
end
