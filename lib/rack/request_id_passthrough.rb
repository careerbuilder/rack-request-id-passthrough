require 'securerandom'
require 'net/http'

module Rack
  class RequestIDPassthrough
    def initialize(app, options={})
      @app = app
      @headers = options.fetch(:source_headers, %w(HTTP_CF_RAY HTTP_X_REQUEST_ID))
      @outgoing_header = options.fetch(:outgoing_headers, %w(X-Request-Id))
      @patch_http = options.fetch(:add_request_id_to_http, true)
    end

    def call(env)
      status, headers, response = @app.call(env)
      Thread.current[:request_id_passthrough] = determine_request_id(env)
      Thread.current[:add_request_id_to_http] = @patch_http
      populate_headers(headers)
      [status, headers, response]
    end

    private

    def determine_request_id(env)
      request_id = SecureRandom.hex
      @headers.reverse.each do |header_name|
        request_id = env[header_name] if env[header_name]
      end
      request_id
    end

    def populate_headers(headers)
      @outgoing_header.each do |header_name|
        headers[header_name] = Thread.current[:request_id_passthrough]
      end
    end
  end
end

module Net::HTTPHeader
  alias original_initialize_http_header initialize_http_header

  def initialize_http_header(initheader)
    if Thread.current[:add_request_id_to_http] && Thread.current[:request_id_passthrough]
      initheader ||= {}
      initheader['x-request-id'] = Thread.current[:request_id_passthrough]
    end
    original_initialize_http_header(initheader)
  end
end
