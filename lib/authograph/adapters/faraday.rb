module Authograph::Adapters
  class Faraday < Base
    def initialize(_request)
      @request = _request
    end

    def get_header(_header)
      @request.headers[_header]
    end

    def set_header(_header, _value)
      @request.headers[_header] = _value
    end

    def method
      @request.method.to_s.upcase
    end

    def path
      URI(@request.path).request_uri
    end

    def content_type
      @request.headers['Content-Type'] || ''
    end

    def body
      @request.body
    end
  end
end
