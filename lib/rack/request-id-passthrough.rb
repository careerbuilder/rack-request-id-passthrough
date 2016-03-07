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
require_relative '../rack-request-id-passthrough/rack-request-id-passthrough'

module Rack
  class RequestIDPassthrough
    def initialize(app, options = {})
      @app = app
      @headers = RackRequestIDPassthrough.source_headers
      @outgoing_header = RackRequestIDPassthrough.response_headers
      @patch_http = (RackRequestIDPassthrough.http_headers.length > 0)
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

      env.each do |k, v|
        @headers.find do |header|
          matches[header] = v if same_header?(header, k)
        end
      end

      @headers.find do |header_name|
        request_id = matches[header_name] if matches[header_name]
      end

      request_id
    end

    def same_header?(header_name, env_key)
      h = header_name.upcase.gsub('_','-').gsub('HTTP-','')
      k = env_key.upcase.gsub('_','-').gsub('HTTP-','')
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
      RackRequestIDPassthrough.http_headers.each do |header|
        initheader[header] = Thread.current[:request_id_passthrough]
      end
    end
    original_initialize_http_header(initheader)
  end
end
