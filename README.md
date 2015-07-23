Google Syncinator [![Build Status](https://travis-ci.org/biola/google-syncinator.svg?branch=master)](https://travis-ci.org/biola/google-syncinator)
=================

Google Syncinator creates and syncs accounts from [trogdir-api](https://github.com/biola/trogdir-api) into a Google Apps domain.

Requirements
------------
- Ruby
- Redis server (for Sidekiq)
- MongoDB server
- trogdir-api installation
- Admin access to a Google Apps account
- Biola WS email table (just temporarily for legacy support)

Installation
------------
```bash
git clone git@github.com:biola/google-syncinator.git
cd google-syncinator
bundle install
cp config/settings.local.yml.example config/settings.local.yml
cp config/blazing.rb.example config/blazing.rb
```

Authentication
--------------
In order to access the Google API, a client cert needs to be created and configured.

1. Visit https://console.developers.google.com/project and create a project
2. Enable the `Admin SDK` under `APIs & auth` > `APIs`
3. Click `Create new Client ID` and choose `Service Account` under `APIs & auth` > `Credentials`
4. Click `Generate new P12 key` under `APIs & auth` > `Credentials`
5. Set the private key's password in `config/settings.local.yml` under `google.api_client.secret`
6. Set the Service Account `Email address` in `config/settings.local.yml` under `google.api_client.issuer`
7. Set `google.api_client.key_path` in `config/settings.local.yml` to the path of the `.p12` file you just downloaded.
8. Login to `admin.google.com`. Go to `Security` > `Show more` > `Advanced settings` > `Manage API client access`
9. Add a new Authorized API client using the `Client ID` from the Developer Console as the `Client Name` and set the `API Scopes` field to the follow comma separated list of scopes:
```
https://www.googleapis.com/auth/admin.directory.group,https://www.googleapis.com/auth/admin.directory.group.member,https://www.googleapis.com/auth/admin.directory.user,https://www.googleapis.com/auth/admin.reports.usage.readonly
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

Testing
-------

*Before running the specs you'll need to create a `ws_test` MySQL database.*

```ruby
bundle exec rspec
```

Deployment
----------
```bash
blazing setup [target name in blazing.rb]
git push [target name in blazing.rb]
```
