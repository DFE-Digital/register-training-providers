module Faker
  class Token < Base
    class << self
      def hex(length = 32)
        bytes_needed = (length / 2.0).ceil
        random_bytes = Array.new(bytes_needed) { Faker::Config.random.rand(256) }
        random_bytes.pack("C*").unpack1("H*")[0, length]
      end
    end
  end
end
