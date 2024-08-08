require 'spec_helper'

RSpec.describe HealthCheck, type: :request do
  it 'works' do
    get '/health_check'
    expect(response.status).to be_ok
  end
end
