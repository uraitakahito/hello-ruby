# frozen_string_literal: true

require_relative '../lib/calculate'

RSpec.describe Calculate do
  it 'calculates half of 1000' do
    calculate = described_class.new(1000)
    expect(calculate.half_num).to eq 500
  end
end
