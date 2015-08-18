module HR
  class RelationProxy < BasicObject

    module CaseFixer
      def ===(other)
        other = other.ar_relation while ::HR::RelationProxy === other
        super
      end
    end

    attr_accessor :ar_relation

    def initialize relation, replica_name
      @ar_relation = relation
      @replica_name = replica_name
    end

    def method_missing(method, *args, &block)
      old_replica = nil
      begin
        old_replica = ::Thread.current[:hr_replica]
        ::Thread.current[:hr_replica] = @replica_name
        r = @ar_relation.public_send(method, *args, &block)
        r = HR::RelationProxy.new(r, @replica_name) if ::ActiveRecord::Relation === r and not HR::RelationProxy === r
        r
      ensure
        ::Thread.current[:hr_replica] = old_replica;
      end

    end

    def ==(other)
      case other
        when ::HR::RelationProxy
          method_missing(:==, other.ar_relation)
        else
          method_missing(:==, other)
      end
    end
    alias_method :eql?, :==
  end
end

::ActiveRecord::Relation.extend(HR::RelationProxy::CaseFixer)