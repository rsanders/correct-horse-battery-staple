source :rubygems

# data formats
gem "fastercsv", :platforms => [:mri_18, :jruby]
gem "json"

# performance
gem "memoizable"

# external DBs
gem "sqlite3", :platforms => [:mri]
gem "redis"

platform :mri do
  gem "hiredis"
end

# cmdline
gem "commander"
platform :jruby do
  gem "ffi-ncurses"
end

gem "rdoc"

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

  # CI
  gem "tddium"
end
