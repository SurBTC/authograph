require "authograph/version"
require "authograph/time_signer"

module Authograph
  def self.time_signer(*_args)
    TimeSigner.new(*_args)
  end
end
