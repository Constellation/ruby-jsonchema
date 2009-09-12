# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{jsonschema}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Constellation"]
  s.date = %q{2009-09-13}
  s.description = %q{json schema library ruby porting from http://code.google.com/p/jsonschema/}
  s.email = %q{utatane.tea@gmail.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "test/jsonschema_test.rb", "lib/jsonschema.rb"]
  s.homepage = %q{http://github.com/Constellation/jsonschema/tree/master}
  s.rdoc_options = ["--main", "README.rdoc", "--charset", "utf-8", "--line-numbers", "--inline-source"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{jsonschema}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{json schema library ruby porting from http://code.google.com/p/jsonschema/}
  s.test_files = ["test/jsonschema_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
