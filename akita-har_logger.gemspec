# frozen_string_literal: true

require_relative 'lib/akita/har_logger/version'

Gem::Specification.new do |spec|
  spec.name          = 'akita-har_logger'
  spec.version       = Akita::HarLogger::VERSION
  spec.authors       = ['Jed Liu']
  spec.email         = ['jed@akitasoftware.com']

  spec.summary       = 'Rails middleware for HAR logging'
  spec.description   = 'Middleware instrumentation for logging HTTP ' \
                       'request-response pairs to a HAR file.'
  spec.homepage      = 'https://akitasoftware.com/'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] =
    'https://github.com/akitasoftware/akita-rails-har-logger'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added
  # into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f|
      f.match(%r{\A(?:test|spec|features)/})
    }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'json', '~> 2.3'

  spec.add_development_dependency 'rspec', '~> 3.10'
end
