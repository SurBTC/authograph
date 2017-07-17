require "authograph/version"
require "authograph/adapters/base"
require "authograph/signer"

module Authograph
  def self.signer(*_args)
    Signer.new(*_args)
  end
end
