module SpreeTcb
  class BaseJob < Spree::BaseJob
    queue_as SpreeTcb.queue
  end
end
