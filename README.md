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
# somewhere in your app maybe an initializer?
RackRequestIDPassthrough.source_headers: %w(HTTP_FUNKY_TOWN HTTP_LESS_IMPORTANT) # List of source headers to look for request ids in
RackRequestIDPassthrough.response_headers: %w(OUTGOING) # Controls the response headers sent back to the browser
RackRequestIDPassthrough.http_headers: %w(OUTGOING_CALL) # Name of http headers that will be appended to all outgoing http calls

# ./config/application.rb
config.middleware.insert_after Rack::RequestIDPassthrough
```
There are three main configuration options
- source_headers: An array of headers to look for incoming request id values
- outgoing_headers: An array of headers which will be appended to all outgoing http/https requests
- http_headers: An array of http headers that will be appended to all outgoing http calls, if you don't want to append then set this to []

So in the example above ridp would check the HTTP headers FUNKY_TOWN and LESS_IMPORTANT for a value (in that order).  If it found one it would add it ```Thread.current[:request_id_passthrough]``` for usage.  It would also add an HTTP header called OUTGOING to all http requests going thru net/http that contains the request id. 

## Contributing

See [here](https://github.com/usbsnowcrash/rack-request-id-passthrough/blob/master/CONTRIBUTING.md)
