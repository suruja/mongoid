source "http://rubygems.org"
gemspec

gem "rake"
gem "moped", git: "git://github.com/mongoid/moped.git"

platforms :mri_19 do
  unless ENV["CI"]
    gem "ruby-debug19", :require => "ruby-debug"
  end
end
