# frozen_string_literal: true

require_relative '../lib/use_github_gem'

RSpec.describe 'Use GitHub Gem' do
  it 'returns hello from hello_gem' do
    expect(hello).to eq 'Hi there!'
  end
end
