module Authograph::Adapters
  class Rack
    def initialize(_request)
      @request = _request
    end

    def get_header(_header)
      @request.env[normalize_header(_header)]
    end

    def set_header(_header, _value)
      @request.env[normalize_header(_header)] = _value
    end

    def method
      @request.request_method.upcase
    end

    def path
      @request.fullpath
    end

    def content_type
      @request.content_type
    end

    def body
      return '' unless @request.body
      data = @request.body.read
      @request.body.rewind
      data
    end

    private

    def normalize_header(_header)
      'HTTP_' + _header.underscore.upcase
    end
  end
end
