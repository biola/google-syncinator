Google Syncinator [![Build Status](https://travis-ci.org/biola/google-syncinator.svg?branch=master)](https://travis-ci.org/biola/google-syncinator)
=================

Google Syncinator creates and syncs accounts from [trogdir-api](https://github.com/biola/trogdir-api) into a Google Apps domain. It handles the deprovisioning of Google accounts when people lose affiliations or become inactive. It also has an API for clients to manage email account data.

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

Adding Clients
--------------

```ruby
irb -r ./config/environment.rb
c = Client.create! name: 'YOUR_CLIENT_NAME_HERE'
c.access_id # to see the access_id
c.secret_key # to see the secret_key
```

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

Scheduled Jobs
--------------
- `Workers::HandleChanges` processes changes from trogdir-api
- `Workers::CheckNeverActive` checks for accounts that don't need to have an email account and have never logged in
- `Workers::CheckInactive` checks for accounts that don't need to have an email account and haven't logged in in a long time.

Notes
-----

- There are 4 sources where data is managed and synced:
  - MongoDB
  - trogdir-api
  - legacy email table
  - Google APIs.
- `ServiceObjects::HandleChange` basically serves as the router for Trogdir changes. It's a good place to start if you're debugging.
- The email models have a fairly complex inheritance structure but it works well. Here it is:
  - `UniversityEmail`
    - `AccountEmail`
      - `PersonEmail`
    - `AliasEmail`
- `DeprovisionSchedule` models also store activate actions, which technically is for reprovisioning. But `DeprovisionOrReprovisionSchedule` doesn't really roll off the tongue now, does it.
- `Exclusion` models prevent deprovisioning or reprovisioning from happening to an email account for a certain amount of time.
- `AliasEmail` models are always tied to an `AccountEmail` which mirrors the relationship aliases have to accounts in Google.
- Email addresses for employees and similar affiliations do not typically include a middle initial. Such as `john.doe@biola.edu`. Students and similar affiliations do include a middle initial. Such as `jane.h.doe@biola.edu`.
- Many operations are run through workers to ensure there are no issues with network failures or API downtimes.
- [three-keepers](https://github.com/biola/three-keepers) has a GUI designed to manage email data through the API.
- [google-syncinator-api-client](https://github.com/biola/google-syncinator-api-client) is a gem to assist in consuming the API.

License
-------
[MIT](https://github.com/biola/google-syncinator/blob/master/MIT-LICENSE)
