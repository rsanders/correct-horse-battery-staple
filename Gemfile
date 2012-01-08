source :rubygems

# data formats
gem "fastercsv", :platforms => [:mri_18, :jruby]
gem "json"

# performance
gem "memoizable"

# external DBs
gem "sqlite3", :platforms => [:mri]

platform :mri do
  gem "hiredis"
  gem "redis", ">= 2.2.0" # , :require => ["redis", "redis/connection/hiredis"]
end

platform :jruby do
  gem "redis", ">= 2.2.0"  
end

gem "tupalo-kdtree"
gem "algorithms"

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
