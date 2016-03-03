# Copyright 2016 CareerBuilder, LLC
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
require 'securerandom'
require 'net/http'

module Rack
  class RequestIDPassthrough
    def initialize(app, options = {})
      @app = app
      @headers = options.fetch(:source_headers, %w(CF-RAY X-Request-Id))
      @outgoing_header = options.fetch(:outgoing_headers, %w(REQUEST_ID))
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
      request_id = SecureRandom.uuid
      matches = {}
      env.each do |key,value|
        @headers.reverse_each do |header_name|
          matches[header_name] = value if same_header?(header_name,key)
        end
      end
      @headers.reverse_each do |header_name|
        request_id = matches[header_name] if matches[header_name]
      end

      request_id
    end

    def same_header?(header_name,key)
      h = header_name.upcase.gsub('_','-').gsub('HTTP-','')
      k = key.upcase.gsub('_','-').gsub('HTTP-','')
      h == k
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
      initheader['REQUEST_ID'] = Thread.current[:request_id_passthrough]
    end
    original_initialize_http_header(initheader)
  end
end
