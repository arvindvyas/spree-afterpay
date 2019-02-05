lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_afterpay/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_afterpay'
  s.version     = SpreeAfterpay::VERSION
  s.summary     = 'Adds spree_afterpay as a Payment Method to Spree Commerce'
  s.description = s.summary
  s.required_ruby_version = '>= 2.1.0'

  s.author       = 'Arvind Vyas'
  s.email        = 'arvindvyas07@gmail.com'
  s.homepage     = 'https://github.com/arvindvyas/spree-fterpay'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'database_cleaner', '1.0.1'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec-rails', '~> 2.14.0'
  s.add_development_dependency 'simplecov'
end
