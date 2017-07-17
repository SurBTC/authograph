module Authograph
  class Signer
    DEFAULT_SIGN_HEADER = 'X-Signature'
    DEFAULT_DATE_HEADER = 'X-Date'

    def initialize(
      digest: 'sha384',
      header: DEFAULT_SIGN_HEADER,
      sign_headers: [],
      sign_date: true,
      date_header: DEFAULT_DATE_HEADER,
      date_max_skew: 600
    )
      @digest = digest
      @header = header
      @sign_headers = sign_headers

      @sign_date = sign_date
      @date_header = date_header
      @date_max_skew = date_max_skew
      @sign_headers << date_header if sign_date # ensure date header is signed too
    end

    def sign(_request, _key_secret)
      _request = adapt _request

      set_request_date(_request) if @sign_date
      # TODO: set_hashed_content to discard invalid signatures before checking content?
      set_request_authorization(_request, _key_secret)
    end

    def authentic?(_request, _key_secret)
      _request = adapt _request

      return false if !signatures_match? _request, _key_secret
      return false if @sign_date && !request_within_time_window?(_request)
      true
    end

    private

    def adapt(_request) # rubocop:disable Metrics/MethodLength
      return _request if _request.is_a? Adapters::Base

      case _request.class.to_s
      when 'ActionDispatch::Request'
        require 'authograph/adapters/rack'
        Adapters::Rack.new Rack::Request.new(_request.env)
      when 'Rack::Request'
        require 'authograph/adapters/rack'
        Adapters::Rack.new _request
      when /^Net::HTTP::.*/
        require 'authograph/adapters/http'
        Adapters::Http.new _request
      when 'Faraday::Request'
        require 'authograph/adapters/faraday'
        Adapters::Faraday.new _request
      else
        raise ArgumentError, 'the given request type is not supported'
      end
    end

    def set_request_date(_request)
      _request.set_header @date_header, Time.now.utc.httpdate
    end

    def set_request_authorization(_request, _key_secret)
      _request.set_header @header, calc_signature(_request, _key_secret)
    end

    def signatures_match?(_request, _key_secret)
      calc_signature(_request, _key_secret) == _request.get_header(@header)
    end

    def request_within_time_window?(_request)
      request_date = Time.httpdate(_request.get_header(@date_header)).utc
      (request_date - Time.now.utc).abs <= @date_max_skew
    rescue ArgumentError
      false
    end

    def calc_signature(_request, _key_secret)
      signature = OpenSSL::HMAC.digest(@digest, _key_secret, build_payload(_request))
      "HMAC-#{@digest.upcase} #{[signature].pack('m0')}"
    end

    def build_payload(_request)
      parts = [
        _request.method,
        _request.path
      ]

      if %w[POST PUT].include?(_request.method)
        parts << _request.content_type || ''
        parts << body_md5(_request)
      end

      # extra headers to be considered
      @sign_headers.each { |h| parts << (_request.get_header(h) || '') }
      parts.join "\n"
    end

    def body_md5(_request)
      Digest::MD5.base64digest _request.body
    end
  end
end
