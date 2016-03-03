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

describe Rack::RequestIDPassthrough do
  let(:app) { ->(env) { [200, {}, [env.to_yaml]] } }
  let(:stack) { Rack::RequestIDPassthrough.new app }
  let(:request) { Rack::MockRequest.new stack }

  before do

  end

  it 'should generate random request IDs' do
    first_response = request.get('/')
    second_response = request.get('/')
    expect(first_response.headers['X-REQUEST-ID']).not_to eq(second_response.headers['X-Request-Id'])
  end

  it 'should return the request ID in the response headers' do
    response = request.get '/'
    expect(response.headers['X-REQUEST-ID']).not_to be_empty
  end

  it 'should persist and existing request ID' do
    response = request.get '/', 'HTTP_CF_RAY' => 'cloudflaretestid'
    expect(response.headers['X-REQUEST-ID']).to eq('cloudflaretestid')
  end

  it 'should choose which id to persist in order' do
    response = request.get '/', 'HTTP_CF_RAY' => 'cloudflaretestid', 'HTTP_X_REQUEST_ID' => 'someotherid'
    expect(response.headers['X-REQUEST-ID']).to eq('cloudflaretestid')
  end

  it 'should set a global constant containing the request id' do
    response = request.get '/'
    expect(Thread.current[:add_request_id_to_http]).to be_truthy
    expect(Thread.current[:request_id_passthrough]).to eq(response.headers['X-REQUEST-ID'])
  end
end
