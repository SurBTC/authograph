module Authograph::Adapters
  class Http < Base
    def initialize(_request)
      @request = _request
    end

    def get_header(_header)
      @request[_header]
    end

    def set_header(_header, _value)
      @request[_header] = _value
    end

    def method
      @request.method.to_s.upcase
    end

    def path
      @request.path
    end

    def content_type
      @request['Content-Type'] || ''
    end

    def body
      if !@request.body_stream.nil?
        data = @request.body_stream.read
        @request.body_stream.rewind
        data
      elsif !@request.body.nil?
        @request.body
      else
        ''
      end
    end
  end
end
