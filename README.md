# Rack::RequestIDPassthrough

Rack middleware which will take incoming headers (such as request id) and ensure that they are passed along to outgoing http requests.
This can be used to track a request throughout your architecture by ensuring that all networks calls will recieve the same request id as the request originator.  An example of such an envrionment would be as follows:

![Diagram](https://raw.githubusercontent.com/usbsnowcrash/rack-request-id-passthrough/master/diagram.png "Diagram")

## Installation

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
    # warning! Make sure that you insert this middleware early so that you can capture all relevant network calls
    config.middleware.insert_after Rack::Runtime, Rack::RequestIDPassthrough, {opts}
  end
end
```

## Configuration Example
```ruby
config.middleware.insert_after Rack::RequestIDPassthrough, {source_headers: %w(HTTP_FUNKY_TOWN HTTP_LESS_IMPORTANT), 
                             outgoing_headers: ['OUTGOING'], add_request_id_to_http: true}
```
There are three main configuration options
- source_headers: An array of headers to look for incoming request id values
- outgoing_headers: An array of headers which will be appended to all outgoing http/https requests
- add_request_id_to_http: A boolean indicating wether or not to patch outgoing http requests

## Contributing

See here
