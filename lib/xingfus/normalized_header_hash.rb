module Xingfus
  class NormalizedHeaderHash < ::Hash
    def initialize(constructor = {})
      if constructor.is_a?(Hash)
        super
        update(constructor)
      else
        super(constructor)
      end
    end

    def fetch(key, *extras)
      super(convert_key(key), *extras)
    end

    def key?(key)
      super(convert_key(key))
    end

    [:include?, :has_key?, :member?].each do |method|
      alias_method method, :key?
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      super(convert_key(key), value)
    end

    def update(other_hash)
      other_hash.each_pair do |key, value|
        self[convert_key(key)] = value
      end
      self
    end

    alias_method :merge!, :update

    def dup
      self.class.new(self)
    end

    def merge(hash)
      self.dup.update(hash)
    end

    def delete(key)
      super(convert_key(key))
    end

  private
    def convert_key(key)
      key.to_s.tr('_'.freeze,'-'.freeze).split('-'.freeze).map! { |segment| segment.capitalize }.join('-'.freeze)
    end
  end
end
