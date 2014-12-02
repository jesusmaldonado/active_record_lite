require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]

      second_table_name = through_options.class_name.constantize.table_name
      through_foreign_key = through_options.foreign_key

      source_options = through_options.model_class.assoc_options[source_name]
      #only self's foreign keys and shit can be referenced so u have to deal w/ symbols.
      third_table_name = source_options.class_name.constantize.table_name
      source_foreign_key = source_options.foreign_key
      p source_options.class_name.constantize
      query = DBConnection.execute(<<-SQL, self.id)
      SELECT
        #{third_table_name}.*
      FROM
        #{self.class.table_name}
      INNER JOIN
        #{second_table_name}
      ON
        #{self.class.table_name}.#{through_foreign_key} = #{second_table_name}.id
      INNER JOIN
        #{third_table_name}
      ON
        #{second_table_name}.#{source_foreign_key} = #{third_table_name}.id
      WHERE
        #{self.class.table_name}.id = ?
      SQL

      source_options.class_name.constantize.parse_all(query).first
    end
  end
end
