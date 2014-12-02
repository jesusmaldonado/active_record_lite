require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      class_name: name.to_s.camelcase,
      primary_key: :id,
      foreign_key: "#{name}_id".to_sym
    }

    new_hash = defaults.merge(options)
    new_hash.each do |method, value|
      self.send("#{method}=", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelcase,
      primary_key: :id,
      foreign_key: ("#{self_class_name}".downcase + "_id").to_sym
    }

    new_hash = defaults.merge(options)
    new_hash.each do |method, value|
      self.send("#{method}=", value)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
      define_method(name) do
        foreign_key = options.send(:foreign_key)
        primary_key = options.send(:primary_key)
        options.model_class.where({options.primary_key => self.send(foreign_key)}).first
      end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
      define_method(name.to_s.downcase.pluralize) do
        foreign_key = options.send(:foreign_key)
        primary_key = options.send(:primary_key)
        options.model_class.where({options.foreign_key => self.send(primary_key)})
      end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
