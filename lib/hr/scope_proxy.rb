module HR
  class ScopeProxy < BasicObject

    module CaseFixer
      def ===(other)
        other = other.klass while ::HR::ScopeProxy === other
        super
      end
    end

    attr_accessor :klass

    def initialize replica_name, klass
      @replica_name = replica_name
      @klass = klass
    end

    def using replica_name
      @replica_name = replica_name
      self
    end

    # Transaction Method send all queries to a specified shard.
    def transaction(options = {}, &block)
      old_replica = nil
      begin
        old_replica = Thread.current['hr_replica']
        Thread.current[:hr_replica] = @replica_name
        @klass = @klass.transaction(options, &block)
      ensure
        Thread.current[:hr_replica] = old_replica;
      end
    end


    def connection
      replica = Thread.current[:hr_replica]
      if replica.blank?
        @klass.connection
      else
        # get connection from proxy
        conn_pool = @klass.class_variable_get(:@@hr_connection_pool)
        conn_pool.connection
      end
    end

    def method_missing(method, *args, &block)

      old_replica = nil
      begin
        old_replica = ::Thread.current[:hr_replica]
        ::Thread.current[:hr_replica] = @replica_name
        r = @klass.send(method, *args, &block)
        r = ::HR::RelationProxy.new(r, @replica_name) if ::ActiveRecord::Relation === r and not ::HR::RelationProxy === r

        if r.respond_to?(:all)
          @klass = r
          return self
        end
        r
      ensure
        ::Thread.current[:hr_replica] = old_replica;
      end
    end

    # Delegates to method_missing (instead of @klass) so that User.using(:blah).where(:name => "Mike")
    # gets run in the correct shard context when #== is evaluated.
    def ==(other)
      method_missing(:==, other)
    end
    alias_method :eql?, :==

  end
end

::ActiveRecord::Relation.extend(::HR::ScopeProxy::CaseFixer)
