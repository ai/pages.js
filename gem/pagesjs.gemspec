# encoding: utf-8

Gem::Specification.new do |s|
  s.name        = 'pagesjs'
  s.version     = '0.0.4'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Andrey "A.I." Sitnik']
  s.email       = ['andrey@sitnik.ru']
  s.homepage    = 'https://github.com/ai/pages.js'
  s.summary     = 'Pages.js - is a framework for History pushState.'
  s.description = 'Pages.js allow you to manage pages JS code and ' +
                  'forget about low-level History API.'

  s.add_dependency 'sprockets', '>= 2'

  s.files            = ['vendor/assets/javascripts/pages.js',
                        'lib/pagesjs.rb',
                        'LICENSE', 'README.md', 'ChangeLog']
  s.extra_rdoc_files = ['LICENSE', 'README.md', 'ChangeLog']
  s.require_path     = 'lib'
end
