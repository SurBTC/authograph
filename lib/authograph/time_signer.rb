module Authograph
  class TimeSigner
    DEFAULT_AUTH_HEADER = 'X-Signature'
    DEFAULT_DATE_HEADER = 'X-Date'

    def initialize(
      digest: 'sha384',
      clock_skew: 600,
      auth_header: nil,
      date_header: nil,
      signed_headers: []
    )
      @digest = digest
      @clock_skew = clock_skew
      @auth_header = auth_header || DEFAULT_AUTH_HEADER
      @date_header = date_header || DEFAULT_DATE_HEADER
      @signed_headers = signed_headers
    end

    def sign(_request, _key_secret)
      _request = adapt _request

      set_request_date(_request)
      # TODO: set_hashed_content to discard invalid signatures before checking content?
      set_request_authorization(_request, _key_secret)
    end

    def authentic?(_request, _key_secret)
      _request = adapt _request

      return false if !signatures_match? _request, _key_secret
      return false if !request_within_time_window? _request
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
      _request.set_header @auth_header, calc_signature(_request, _key_secret)
    end

    def signatures_match?(_request, _key_secret)
      calc_signature(_request, _key_secret) == _request.get_header(@auth_header)
    end

    def request_within_time_window?(_request)
      request_date = Time.httpdate(_request.get_header(@date_header)).utc
      request_date > (Time.now.utc - @clock_skew) && request_date < (Time.now.utc + @clock_skew)
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
        _request.path,
        _request.get_header(@date_header) || '',
        _request.content_type || '',
        body_md5(_request)
      ]

      # extra headers to be considered
      @signed_headers.each { |h| parts << (_request.get_header(h) || '') }
      parts.join "\n"
    end

    def body_md5(_request)
      if %w[POST PUT].include?(_request.method)
        Digest::MD5.base64digest _request.body
      else
        ''
      end
    end
  end
end
