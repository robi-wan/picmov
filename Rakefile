require 'rake'

require 'rake/gempackagetask'

task :default => [:run]

task :run do
  `shoes #{File.join(File.dirname(__FILE__),"picmov_shoes.rb")}`
end

# Generate GEM ----------------------------------------------------------------------------

PKG_FILES = FileList[
  'R[a-zA-Z]*',
  'bin/**/*',
  'lib/**/*'
] - [ 'test' ]

spec = Gem::Specification.new do |s|
  s.name = 'picmov'
  s.version = '0.0.1'
  s.author = "Robert Schröder"
  s.email = 'robi-wan@suyu.de'
  s.homepage = 'http://github.com/robi-wan/picmov/'
  s.summary = 'PicMov is a very simple module to move and rename pictures.'

  #s.files = %w(Rakefile bin/picmov)
  #s.files += %w(lib/picmov.rb lib/picmov/picmov.rb lib/picmov/settings.rb)
  s.files = PKG_FILES.to_a
  s.executables = %w(picmov)
  s.default_executable = "picmov"

  s.has_rdoc = false
  ##s.rdoc_options = ['--title', 'Picture Mover API Documentation', '--main', 'README.rdoc']
  #s.extra_rdoc_files = %w(README.rdoc CHANGELOG)

    if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<exifr>)
    else
      s.add_dependency(%q<exifr>)
    end
  else
    s.add_dependency(%q<exifr>)
  end
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end 
