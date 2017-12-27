require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = "--color --backtrace"
end

desc "Start up the test servers"
task :start_test_servers do
  puts "Starting 3 test servers"
  (3000..3002).map do |port|
    Thread.new do
      system("ruby spec/servers/app.rb -p #{port}")
    end
  end.each(&:join)
end

task :default => :spec

desc "compile C extension"
task :compile do
  system "cd ext/typhoeus && ruby extconf.rb && make"
end

desc "clean compilation artefacts"
task :clean do
  system "make -C ext/typhoeus clean"
end
