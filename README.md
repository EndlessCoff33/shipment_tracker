# Shipment Tracker
[![Circle CI](https://img.shields.io/circleci/project/FundingCircle/shipment_tracker/master.svg)](https://circleci.com/gh/FundingCircle/shipment_tracker)
[![Code Climate](https://img.shields.io/codeclimate/github/FundingCircle/shipment_tracker.svg)](https://codeclimate.com/github/FundingCircle/shipment_tracker)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/FundingCircle/shipment_tracker.svg)](https://codeclimate.com/github/FundingCircle/shipment_tracker)

[![](http://i.imgur.com/VkjlJmj.jpg)](https://www.flickr.com/photos/britishlibrary/11237769263/)

Tracks shipment of software versions for audit purposes.

The app has various "audit endpoints" to receive events,
such as deploys, builds, ticket creations, etc.

All received events are stored in the DB and are never modified.
[Event sourcing] is used to replay each event allowing us to reconstruct the state
of the system at any point in time.

## Getting Started

Install the Ruby version specified in `.ruby-version`.

Install the Gems.

```
bundle install
```

Setup database and environment.

```
cp .env.development.example .env.development
bundle exec rake db:setup
```

Set up Git hooks, for running tests and linters before pushing to master.

```
bundle exec rake git:setup_hooks
```

### Enabling access to repositories via SSH

Ensure that `libssh2` is installed and the `rugged` gem is reinstalled. On OSX:

```
brew install libssh2
gem pristine rugged
```

When booting server, set Environment variables `SSH_USER`, `SSH_PUBLIC_KEY` and `SSH_PRIVATE_KEY`:

```
SSH_USER=git \
SSH_PUBLIC_KEY='ssh-rsa AAAXYZ' \
SSH_PRIVATE_KEY='-----BEGIN RSA PRIVATE KEY-----
abcdefghijklmnopqrstuvwxyz
-----END RSA PRIVATE KEY-----' \
rails s -p 1201
```

Note that port 1201 is only needed in development; it's the expected port by auth0 (the service we use for authentication).

You can also use Foreman to start the server and use settings from Heroku:

```
bin/boot_with_heroku_settings
```

### Running periodic snapshots

In order to return results with recent events, Shipment Tracker needs to continuously record snapshots.  
This can be setup using the [Whenever Gem] or, if you're on Heroku, using the [Heroku Scheduler].

Please make sure the following command runs every few seconds:

```
bundle exec rake jobs:update_events
```

*Warning:* This recurring task should only run on **one** server.

### Enabling periodic git fetching

It's important to keep the Shipment Tracker git cache reasonably up-to-date to avoid request timeouts.

Please make sure the following command runs every few minutes:

```
bundle exec rake jobs:update_git
```

*Warning:* This recurring task should run on **every** server that your application is running on.

## License

Copyright © 2015 Funding Circle Ltd.

Distributed under the BSD 3-Clause License.

[Event sourcing]: http://www.infoq.com/presentations/Events-Are-Not-Just-for-Notifications
[Whenever Gem]: https://github.com/javan/whenever
[Heroku Scheduler]: https://devcenter.heroku.com/articles/scheduler
