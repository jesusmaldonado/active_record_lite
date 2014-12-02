require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    search_criteria = params.values
    where_line = params.keys.map{|key| "#{key} = ?"}.join(" AND ")
    query = DBConnection.execute(<<-SQL, *search_criteria)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}
  SQL
  parse_all(query)
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end


#is max the guy with the batman beanie
