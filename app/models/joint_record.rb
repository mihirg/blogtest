class JointRecord < ActiveRecord::Base
  self.abstract_class = true
  class_attribute :_db_config
  class_attribute :_db_replicas

  self._db_config = ''


  def self.establish_db_connection
    databases = YAML::load_file(self._db_config)
    establish_connection databases[Rails.env]

    if !self._db_replicas.blank?
      replicas = YAML::load_file(self._db_replicas)
      configurations = ActiveRecord::ConnectionHandling::MergeAndResolveDefaultUrlConfig.new(replicas).resolve
      resolver =   ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new configurations
      spec     =   resolver.spec(:replica)
      connection_pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)

      self.class_variable_set(:@@hr_connection_pool, connection_pool)
    end
  end
end