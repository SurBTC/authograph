module Authograph::Adapters
  class Webmock < Base
    def initialize(_request)
      @request = _request
    end

    def get_header(_header)
      @request.headers[_header]
    end

    def set_header(_header, _value)
      raise 'not implemented'
    end

    def method
      @request.method.to_s.upcase
    end

    def path
      @request.uri.request_uri
    end

    def content_type
      get_header('Content-Type') || ''
    end

    def body
      @request.body
    end
  end
end
