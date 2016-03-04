
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'rack-request-id-passthrough'
  s.version       = '1.2.0'
  s.summary       = 'Middleware for persisting request IDs'
  s.description   = 'Rack middleware which will take incoming headers (such as request id) and ensure that they are passed along to outgoing http requests'
  s.author        = 'Jeffery Yeary'
  s.email         = 'jeff@debug.ninja'
  s.homepage      = 'https://github.com/careerbuilder/rack-request-id-passthrough'
  s.license       = 'Apache-2.0'
  s.files         = Dir['{lib}/**/*', 'LICENSE', 'NOTICE', '*.md']
  s.require_path  = 'lib'

  s.add_development_dependency 'rack'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rubocop'
end
