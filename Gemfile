source "http://rubygems.org"
gemspec

gem "rake"
gem "moped", path: "/Users/durran/work/moped"

platforms :mri_19 do
  unless ENV["CI"]
    gem "ruby-debug19", :require => "ruby-debug"
  end
end
