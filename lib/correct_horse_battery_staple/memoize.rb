module CorrectHorseBatteryStaple::Memoize
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def memoize(method)
      old_method = "_#{method}_unmemoized".to_sym
      miss_object = Object.new
      alias_method old_method, method
      define_method method do |*args, &block|
        @_memoize_cache ||= {}
        if block
          raise ArgumentError, "You cannot call a memoized method with a block! #{method}"
        end
        value = @_memoize_cache.fetch(args, miss_object)
        if value === miss_object
          value = @_memoize_cache[args] = send(old_method, *args)
        end
        value
      end
    end
  end
end
