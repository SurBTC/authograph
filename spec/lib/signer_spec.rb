require 'spec_helper'

describe Authograph::Signer do
  let!(:time) { Time.now } # stop spec time

  let(:signed_headers) { [] }
  let(:signer) { described_class.new(sign_headers: signed_headers) }

  # request parameters
  let(:adapter) { Class.new(Authograph::Adapters::Base).new }
  let(:method) { 'GET' }
  let(:path) { '/dummy/path' }
  let(:httptime) { time.utc.httpdate }
  let(:content_type) { nil }
  let(:body) { nil }

  before do
    allow(Time).to receive(:now).and_return(time)
    allow(adapter).to receive(:method).and_return method
    allow(adapter).to receive(:path).and_return path
    allow(adapter).to receive(:content_type).and_return content_type
    allow(adapter).to receive(:body).and_return body
    allow(adapter).to receive(:get_header).with('X-Date').and_return httptime
    allow(adapter).to receive(:get_header).with('X-Signature').and_return signature
    allow(adapter).to receive(:set_header)
  end

  let!(:secret) { '300353003530035300353003530035' }
  let(:signature) do
    'HMAC-SHA384 ' +
      [OpenSSL::HMAC.digest('sha384', secret, "#{method}\n#{path}\n#{httptime}")].pack('m0')
  end

  describe '#sign' do
    it 'sets the request date header with the current time' do
      expect(adapter).to receive(:set_header).with('X-Date', httptime)
      signer.sign(adapter, secret)
    end

    it 'sets the request signature header with the correct signature' do
      expect(adapter).to receive(:set_header).with('X-Signature', signature)
      signer.sign(adapter, secret)
    end
  end

  describe '#authentic?' do
    it 'returns true if request signature header matches signature' do
      allow(Time).to receive(:now).and_return(time + 599)

      expect(signer.authentic?(adapter, secret)).to be true
    end

    it 'returns false if signature does not match request' do
      allow(adapter).to receive(:path).and_return '/dummy/path2'

      expect(signer.authentic?(adapter, secret)).to be false
    end

    it 'returns false if too much time has passed since signature' do
      allow(Time).to receive(:now).and_return(time + 601)

      expect(signer.authentic?(adapter, secret)).to be false
    end
  end

  context "for content requests" do
    let(:method) { 'POST' }
    let(:content_type) { 'application/json' }
    let(:body) { '{"some"="content"}' }

    let(:signature) do
      'HMAC-SHA384 ' +
        [OpenSSL::HMAC.digest(
          'sha384',
          secret,
          "#{method}\n#{path}\n#{content_type}\n#{Digest::MD5.base64digest(body)}\n#{httptime}"
        )].pack('m0')
    end

    describe '#sign' do
      it 'sets the request signature header with the correct signature' do
        expect(adapter).to receive(:set_header).with('X-Signature', signature)
        signer.sign(adapter, secret)
      end
    end
  end
end
