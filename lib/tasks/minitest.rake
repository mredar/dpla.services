require "rake/testtask"

# Rails standard integration tests were installed by default
# So we clear these tasks out (idea from:
# https://github.com/blowmage/minitest-rails/commit/4745aed3d77e1eb14becbcf6eb9904382de005e2)
Rake::Task[:test].clear

Rake::TestTask.new(:test => "db:test:prepare") do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

task :default => :test