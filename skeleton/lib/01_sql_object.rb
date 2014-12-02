require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    query = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    query[0].map!{|string| string.to_sym}
  end

  def self.finalize!
    columns.each do |method|

      define_method(method) do
        self.attributes[method]
      end

      define_method("#{method}=") do |value|
        self.attributes[method] = value
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
     @table_name ||= self.to_s.tableize
  end

  def self.all
    query = DBConnection.execute(<<-SQL)
    SELECT
    #{self.table_name}.*
    FROM
    #{self.table_name}
    SQL
    parse_all(query)
  end

  def self.parse_all(results)
    results.map { |attr_hash| self.new(attr_hash) }
  end

  def self.find(id)
    query = DBConnection.execute(<<-SQL, id)
    SELECT
      #{self.table_name}.*
    FROM
      #{self.table_name}
    WHERE
      #{self.table_name}.id = ?
    SQL
    return nil if query.empty?
    self.new(query.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.columns.include?(attr_name.to_sym)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |method| self.send(method) }
  end

  def insert
    col_names = self.class.columns.map(&:to_s).join(", ")
    question_string = "?" * self.class.columns.count
    question_marks = question_string.split("").join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_columns = self.class.columns.map do |method|
      method = method.to_s + " = ?"
    end.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_columns}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
