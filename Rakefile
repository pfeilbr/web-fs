GEMS = %w(sinatra dm-appengine addressable appengine-apis extlib maruku rack syntax json_pure mime-types)

namespace :gem do

  desc "reinstalls all gems for the project"
  task :reinstall => [:clean] do
    sh "rm -fr .gems"
    sh "gem bundle"
    sh "appcfg.rb bundle ."
  end

  desc "builds WEB-INF/lib/gems.jar"
  task :build => [:clean] do
    sh "appcfg.rb bundle ."
  end

  desc "removes WEB-INF/lib/gems.jar"
  task :clean do
    sh "rm -fr WEB-INF/lib/gems.jar"
  end

end