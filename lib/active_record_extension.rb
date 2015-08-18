module ActiveRecordExtension
  extend ActiveSupport::Concern

  module ClassMethods
    def using db_name
      HR::ScopeProxy.new db_name, self
    end

    def connection
      conn_pool = self.class_variable_get(:@@hr_connection_pool)
      replica_name = ::Thread.current[:hr_replica]
      if !conn_pool.blank? && !replica_name.blank?
        return conn_pool.connection
      end
      super
    end


  end

end


#include the extension
ActiveRecord::Base.send(:include, ActiveRecordExtension)
require 'hr/relation_proxy'
require 'hr/scope_proxy'