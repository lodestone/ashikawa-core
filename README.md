# Ashikawa Core

| Project         | Ashikawa::Core
|:----------------|:--------------------------------------------------
| Homepage        | http://triagens.github.io/ashikawa-core/
| Documentation   | [RubyDoc](http://www.rubydoc.info/gems/ashikawa-core)
| CI              | [![Build Status](https://secure.travis-ci.org/triAGENS/ashikawa-core.png?branch=master)](http://travis-ci.org/triAGENS/ashikawa-core)
| Code Metrics    | [![Code Climate](https://codeclimate.com/github/triAGENS/ashikawa-core.png)](https://codeclimate.com/github/triAGENS/ashikawa-core) [![Coverage Status](https://coveralls.io/repos/triAGENS/ashikawa-core/badge.png?branch=coverall)](https://coveralls.io/r/triAGENS/ashikawa-core)
| Gem Version     | [![Gem Version](https://badge.fury.io/rb/ashikawa-core.png)](http://badge.fury.io/rb/ashikawa-core)
| Dependencies    | [![Dependency Status](https://gemnasium.com/triAGENS/ashikawa-core.png)](https://gemnasium.com/triAGENS/ashikawa-core)

Ashikawa Core is a Wrapper around the ArangoDB Rest API. It provides low level access and is intended to be used in ArangoDB ODMs and other projects related to the database. It is always working with the stable version of ArangoDB, this is currently version **1.4**.

All tests run on Travis CI for the following versions of Ruby:

* MRI 1.9.3, 2.0.0 and 2.1.0
* Rubinius 2.2.5
* JRuby 1.7.9 in 1.9 mode

Please note that the [`master`](https://github.com/triAGENS/ashikawa-core) branch is always the stable version released on Ruby Gems and documented on [RDoc](http://www.rubydoc.info/github/triAGENS/ashikawa-core). If you want the most recent version, please refer to the [`development`](https://github.com/triAGENS/ashikawa-core/tree/development) branch.

## How to install it?

```shell
gem install ashikawa-core
```

or, when using bundler:

```ruby
gem "ashikawa-core", "~> 0.10"
```

## How to Setup a Connection?

We want to provide you with as much flexibility as possible. So you can choose which adapter to use for HTTP (choose from the adapters available for [Faraday](https://github.com/lostisland/faraday)) and what you want to use for logging (basically anything that has an `info` method that takes a String). It defaults to Net::HTTP and no logging:

```ruby
database = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:8529"
end
```

If you want to access the `my_db` database of your ArangoDB instance (and not the `_system` database) and connect as a certain user, do the following:

```ruby
database = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:8529/_db/my_db"
  config.username = "lebowski"
  config.password = "i<3bowling"
end
```

But you could for example use Typhoeus for HTTP and yell for logging:

```ruby
require "typhoeus"
require "yell"

logger = Yell.new(STDOUT)

database = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:8529"
  config.adapter = :typhoeus
  config.logger = logger
end
```

For a detailed description on how to use Ashikawa::Core please refer to the [documentation](http://rdoc.info/gems/ashikawa-core/frames). An example:

```ruby
database["my_collection"] # => Returns the collection my_collection – creates it, if it doesn't exist
database["my_collection"].name = "new_name"
database["new_name"].delete
```

# Issues or Questions

If you find a bug in this gem, please report it on [our tracker](https://github.com/triAGENS/ashikawa-core/issues). If you have a question, just contact us via the [mailing list](https://groups.google.com/forum/?fromgroups#!forum/ashikawa) – we are happy to help you :smile:

# Contributing

If you want to contribute to the project, see CONTRIBUTING.md for details. It contains information on our process and how to set up everything. The following people have contributed to this project:

* Lucas Dohmen ([@moonglum](https://github.com/moonglum)): Developer
* Tobias Eilert ([@EinLama](https://github.com/EinLama)): Contributor
* Markus Schirp ([@mbj](https://github.com/mbj)): Contributor
* Ettore Berardi ([@ettomatic](https://github.com/ettomatic)): Contributor
* Samuel Richardson ([@Rodeoclash](https://github.com/Rodeoclash)): Contributor
