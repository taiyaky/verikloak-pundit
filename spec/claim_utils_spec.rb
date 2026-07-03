# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Verikloak::Pundit::ClaimUtils do
  describe '.normalize' do
    it 'returns an empty hash for nil' do
      expect(described_class.normalize(nil)).to eq({})
    end

    it 'returns Hash input unchanged' do
      claims = { 'sub' => '1' }
      expect(described_class.normalize(claims)).to equal(claims)
    end

    it 'coerces objects responding to to_hash' do
      claim_like = Class.new do
        def to_hash
          { 'sub' => '2' }
        end
      end.new

      expect(described_class.normalize(claim_like)).to eq({ 'sub' => '2' })
    end

    it 'returns an empty hash when to_hash returns a non-Hash' do
      claim_like = Class.new do
        def to_hash
          'not a hash'
        end
      end.new

      expect(described_class.normalize(claim_like)).to eq({})
    end

    it 'returns an empty hash for other types' do
      expect(described_class.normalize('string')).to eq({})
      expect(described_class.normalize(42)).to eq({})
      expect(described_class.normalize([1, 2])).to eq({})
    end

    it 'rescues errors raised by to_hash and returns an empty hash' do
      exploding = Class.new do
        def to_hash
          raise 'boom'
        end
      end.new

      expect(described_class.normalize(exploding)).to eq({})
    end

    it 'warns about rescued errors when $DEBUG is enabled' do
      exploding = Class.new do
        def to_hash
          raise 'boom'
        end
      end.new

      original_debug = $DEBUG
      begin
        $DEBUG = true
        expect { described_class.normalize(exploding) }
          .to output(/ClaimUtils\.normalize failed: RuntimeError: boom/).to_stderr
      ensure
        $DEBUG = original_debug
      end
    end
  end
end
