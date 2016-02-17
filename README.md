# Rack::RequestIDPassthrough

Rack middleware which will take incoming headers (such as request id) and ensure that they are passed along to outgoing http requests.

## Usage

```ruby
# Gemfile
gem install 'rack-request-id-passthrough'
```

#### Sinatra (or any rack based stack)

```ruby
# config.ru
class MyApp < Sinatra::Base
  use Rack::RequestIDPassthrough
end
```

#### Rails

```ruby
# ./config/application.rb
module MyApp
  class Application < Rails::Application
    # ...
    config.middleware.use "Rack::RequestIDPassthrough"
  end
end
```

## Configuration

TODO: proc option to override id format

## Contributing

See here