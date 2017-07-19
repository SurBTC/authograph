module Authograph
  module RSpecHelpers
    def stub_authograph(_matcher, _signature = nil)
      if _signature.nil?
        _signature = _matcher
        _matcher = :any
      end

      allow_any_instance_of(Authograph::Signer)
        .to receive(:calc_signature)
        .and_wrap_original do |original, request, secret|
          case _matcher
          when :any
            next _signature
          when Hash
            # TODO
          end

          original.call(request, secret) # fallback to original
        end
    end
  end
end

RSpec.configure do |config|
  config.include Authograph::RSpecHelpers
end
