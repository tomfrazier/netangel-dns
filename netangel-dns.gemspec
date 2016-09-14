# coding: utf-8
lib = File.expand_path( '../lib', __FILE__ )
$LOAD_PATH.unshift( lib ) unless $LOAD_PATH.include?( lib )
require 'netangel/dns/version'

Gem::Specification.new do |spec|
  spec.name          = 'netangel-dns'
  spec.version       = Netangel::Dns::VERSION
  spec.authors       = ['Eric Terry']
  spec.email         = ['eric@netangel.com']

  spec.summary       = 'NetAngel DNS Filter Server'
  spec.description   = 'DNS-based web filter server with blacklists, whitelists, SafeSearch, and per-client customization.'
  spec.homepage      = 'https://www.netangel.com/dns'
  spec.license       = 'GPL-3.0'

  spec.files         = `git ls-files -z`.split( "\x0" ).reject { |f| f.match( %r{^(test|spec|features)/} ) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep( %r{^exe/} ) { |f| File.basename( f ) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_dependency 'thor', '~> 0.19.1'
  spec.add_dependency 'celluloid-dns'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'colorize'
  spec.add_dependency 'git'
  spec.add_dependency 'redis', '~> 3.2'
end
