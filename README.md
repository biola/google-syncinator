Alphabet Syncinator [![Build Status](https://travis-ci.org/biola/alphabet-syncinator.svg?branch=master)](https://travis-ci.org/biola/alphabet-syncinator)
=================

Alphabet Syncinator creates and syncs accounts from [trogdir-api](https://github.com/biola/trogdir-api) into a Alphabet Apps domain.

Requirements
------------
- Ruby
- Redis server (for Sidekiq)
- trogdir-api installation
- Admin access to a Alphabet Apps account

Installation
------------
```bash
git clone git@github.com:biola/alphabet-syncinator.git
cd alphabet-syncinator
bundle install
cp config/settings.local.yml.example config/settings.local.yml
cp config/blazing.rb.example config/blazing.rb
```

Configuration
-------------
- Edit `config/settings.local.yml` accordingly.
- Edit `config/blazing.rb` accordingly.

Running
-------

```ruby
sidekiq -r ./config/environment.rb
```

Deployment
----------
```bash
blazing setup [target name in blazing.rb]
git push [target name in blazing.rb]
```
