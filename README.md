# unifi-api

unifi-api is a ruby client for the Ubiquiti Unifi wireless controller API. Based on the python implementation at https://github.com/calmh/unifi-api.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'unifi-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install unifi-api

## Usage

```ruby
require 'unifi-api'

unifi = Unifi::Api::Controller.new('unifi', 'admin', 'password', 8443, 'v4')

aps = unifi.get_aps
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hculap/unifi-api.

