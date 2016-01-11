class Relation
  include Enumerable


  def initialize(klass, options = {})
    @klass = klass
    defaults = { where_params: [], join_params: [] }
    @options = defaults.merge(options)
    @loaded = false
  end

  def each(&prc)
    to_a.each(&prc)
  end

  def count
    loaded? ? to_a.count : execute_count_query
  end

  def first
    loaded? ? to_a[0] : execute_first_query
  end

  def to_a
    load
    arr
  end

  def reload
    reset
    load
  end

  def reset
    # TODO
  end

  def load
    arr ||= execute_main_query
    @loaded = true
    self
  end

  def loaded?
    @loaded
  end


  def ==(other)
    case other
    when Relation
      other.to_sql == self.to_sql
    when Array
      to_a == other
    else
      false
    end
  end

  private
  attr_accessor :klass, :options



  def execute_main_query
  end

  def execute_count_query
  end

  def execute_first_query

  end

  def main_query
    ["SELECT\n  #{klass.table_name}.*\n", @from_str, @where_str].join("\n")
  end

  def first_query
    main_query + "LIMIT 1"
  end

  def count_query
    ["SELECT\n  COUNT(*) AS count\n", @from_str, @where_str].join
  end

  def build_query
    build_where_str
    build_from_str
  end



  def build_where_str
    @bindings = []
    @where_str =
      if where_params.empty?
        ""
      else
        "WHERE\n  "
      end
    add_where_substr(where_params)
    if @where_str.ends_with(" AND ")
      @where_str = @where_str[0..( -1 - " AND ".length )]
    end
    @where_str += "\n"
  end

  def add_where_substr(where_params)
    case where_params
    when String
      @where_str += where_params + " AND "
    when Array
      join_params.each { |param| add_where_substr(param) }
    when Hash
      join_params.each { |key, value| add_single_condition_where_substr(key, value)}
    end
  end

  def add_single_condition_where_substr(key,value)
    options = klass.assoc_options[name]
    if value.nil?
      @where_str += "#{key} IS NULL AND "
    else
      @bindings << value
      @where_str += "#{key} = ? AND "
    end
  end

  def where_params
    options[:where_params]
  end

  def build_from_str
    @from_str = "FROM\n  #{klass.table_name}\n"
    add_join_str
  end

  def add_join_str
    add_join_substr(join_params)
  end

  def add_join_substr(join_params)
    case join_params
    when String
      @from_str += join_params + "\n"
    when Symbol
      add_single_assoc_join_str(join_params)
    when Array
      join_params.each { |param| add_join_substr(param) }
    when Hash
      join_params.each { |key, value| add_nested_assoc_join_substr(key, value) }
    end
  end

  def add_single_assoc_join_str(name)
    options = klass.assoc_options[name]
    if options.through?
      add_nested_assoc_join_str(options.through, options.source)
    else
      @from_str += "INNER JOIN\n  #{options.table_name} ON"
    end
  end

  def add_nested_assoc_join_str(through, source)
  end

  def join_params
    options[:join_params]
  end
end