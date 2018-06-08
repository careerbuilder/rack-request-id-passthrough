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
require 'yaml'
require 'pry'
require 'net/http'
require 'uri'

describe Rack::RequestIDPassthrough do
  let(:app) { ->(env) { [200, {}, [env.to_yaml]] } }
  let(:stack) { Rack::RequestIDPassthrough.new app }
  let(:request) { Rack::MockRequest.new stack }

  it 'should generate random request IDs' do
    first_response = request.get('/')
    second_response = request.get('/')
    expect(first_response.headers['REQUEST_ID']).not_to eq(second_response.headers['REQUEST_ID'])
  end

  it 'should return the request ID in the response headers' do
    response = request.get '/'
    expect(response.headers['REQUEST_ID']).not_to be_empty
  end

  it 'should persist and existing request ID' do
    response = request.get '/', 'CF-RAY' => 'cloudflaretestid'
    expect(response.headers['REQUEST_ID']).to eq('cloudflaretestid')
  end

  it 'should ignore the casing of the headers' do
    response = request.get '/', 'cf-rAy' => 'cloudflaretestid'
    expect(response.headers['REQUEST_ID']).to eq('cloudflaretestid')
  end

  it 'should ignore the http prepended onto the headers' do
    response = request.get '/', 'HTTP_CF_RAY' => 'cloudflaretestid'
    expect(response.headers['REQUEST_ID']).to eq('cloudflaretestid')
  end

  it 'should treat _ and - the same' do
    response = request.get '/', 'HTTP-CF-RAY' => 'cloudflaretestid'
    expect(response.headers['REQUEST_ID']).to eq('cloudflaretestid')
  end

  it 'should choose which id to persist in order' do
    response = request.get '/', 'CF-RAY' => 'cloudflaretestid', 'X-Request-Id' => 'someotherid'
    expect(response.headers['REQUEST_ID']).to eq('cloudflaretestid')
  end

  it 'should set a global constant containing the request id' do
    response = request.get '/'
    expect(Thread.current[:add_request_id_to_http]).to be_truthy
    expect(Thread.current[:request_id_passthrough]).to eq(response.headers['REQUEST_ID'])
  end
end

describe Net::HTTPHeader do
  let(:app) { ->(env) { [200, {}, [env.to_yaml]] } }
  let(:stack) { Rack::RequestIDPassthrough.new app }
  let(:request) { Rack::MockRequest.new stack }

  context 'we are setup to patch outgoing connections' do
    it 'should append request id to outgoing headers' do
      response = request.get('/')
      stub = stub_request(:get, 'http://example.com/').
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                            'Host'=>'example.com', 'User-Agent'=>'Ruby',
                            'Request-Id'=>response.headers['REQUEST_ID']})
      Net::HTTP.get_response(URI.parse('http://example.com'))
      expect(stub).to have_been_requested
      WebMock.reset!
    end
  end

  context 'we dont want to patch outgoing connections' do
    let(:opts) { {add_request_id_to_http: false} }
    let(:stack) { Rack::RequestIDPassthrough.new(app,opts) }
    it 'should not append request id to outgoing headers' do
      request.get('/')
      stub = stub_request(:get, 'http://example.com/')
      stub_request(:get, 'example.com').with { |request| !request.headers.include?('REQUEST_ID') }
      Net::HTTP.get_response(URI.parse('http://example.com'))
      expect(stub).to have_been_requested
    end
  end
end
