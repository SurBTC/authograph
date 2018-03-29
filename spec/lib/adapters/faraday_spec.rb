require 'spec_helper'
require 'faraday'
require 'authograph/adapters/webmock'
require 'authograph/adapters/faraday'

describe Authograph::Adapters::Faraday do
  let!(:secret) { '300353003530035300353003530035' }
  let(:signer) { Authograph::Signer.new(sign_headers: [], sign_date: false) }

  before { stub_request(:any, /foo\.com/).to_return(status: 200) }

  it "properly encodes simple GET request" do
    Faraday.new.get('http://foo.com/') do |req|
      signer.sign(req, secret)
    end

    expect(
      a_request(:get, /foo\.com/).with do |req|
        expect(signer.authentic?(Authograph::Adapters::Webmock.new(req), secret)).to be true
      end
    ).to have_been_made
  end

  it "properly encodes a GET request with a query string" do
    Faraday.new.get('http://foo.com?foo=bar') do |req|
      signer.sign(req, secret)
    end

    expect(
      a_request(:get, /foo\.com/).with do |req|
        expect(signer.authentic?(Authograph::Adapters::Webmock.new(req), secret)).to be true
      end
    ).to have_been_made
  end

  it "properly encodes a POST request with a query string" do
    Faraday.new.post('http://foo.com?foo=bar', "baz=qux") do |req|
      signer.sign(req, secret)
    end

    expect(
      a_request(:post, /foo\.com/).with do |req|
        expect(signer.authentic?(Authograph::Adapters::Webmock.new(req), secret)).to be true
      end
    ).to have_been_made
  end
end
