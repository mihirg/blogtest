class SuperRecord < JointRecord
  self.abstract_class = true
  self._db_config = 'config/database_recruit.yml'
  self._db_replicas = "config/recruit_replicas.yml"
  establish_db_connection
end