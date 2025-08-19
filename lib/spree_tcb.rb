require 'spree_core'
require 'spree_extension'
require 'spree_tcb/engine'
require 'spree_tcb/version'
require 'spree_tcb/configuration'

module SpreeTcb
  def self.queue
    'default'
  end
end