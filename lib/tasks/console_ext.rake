# Install console helpers
task :console_helpers do
  require_relative 'console_helpers'
end

task console: :console_helpers
