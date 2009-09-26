GEMS = %w(sinatra dm-appengine addressable appengine-apis extlib maruku rack syntax json_pure rest-client mime-types)
task :rebuild => [:clean] do
  sh "rm -fr .gems"
  sh "appcfg.rb gem install #{GEMS.join(' ')}"
  sh "appcfg.rb gem cleanup"
end

task :build => [:clean] do
  sh "appcfg.rb gem cleanup"
end

task :clean do
  sh "rm -fr WEB-INF/lib/gems.jar"
end