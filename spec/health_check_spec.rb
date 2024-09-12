require 'spec_helper'

RSpec.describe HealthCheck, type: :request do
  it 'works' do
    get '/health_check'
    expect(response).to be_ok
  end

  context '/migration' do

  end
end
