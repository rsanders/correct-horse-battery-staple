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
        methcache = (@_memoize_cache[method] ||= {})
        if block
          raise ArgumentError, "You cannot call a memoized method with a block! #{method}"
        end
        value = methcache.fetch(args, miss_object)
        if value === miss_object
          value = methcache[args] = send(old_method, *args)
        end
        value
      end
    end
  end
end
