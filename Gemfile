source :rubygems

# data formats
gem "fastercsv", :platforms => [:mri_18, :jruby]
gem "json"

# performance
# gem "memoizable"

# external DBs

# cmdline
gem "commander"
platform :jruby do
  gem "ffi-ncurses"
end

gem "rdoc"

group :test, :development do
  gem "sqlite3", '>= 1.3.0', :platforms => [:mri]
  gem 'redis', '>= 2.2.2'
  gem 'hiredis', '>= 0.4.0', :platforms => [:mri]
  gem 'tupalo-kdtree', '>= 0.2.3'
end

group :test do
  gem "rspec"
end

group :development do
  # debugging
  gem "pry"

  # gem creation
  gem "rubyforge"
  gem "hoe"
  gem "hoe-git"
  gem "hoe-bundler"
  gem "hoe-yard"
  gem "hoe-gemspec"
  gem "hoe-debugging"

  gem "ruby-prof", :platforms => [:mri]
end

gemspec
