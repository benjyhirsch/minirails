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

  def where(params)
    options = @options.merge(where_params: @options[:where_params] + [params])
    Relation.new(klass, options)
  end

  def count
    loaded? ? to_a.count : DBConnection.execute(count_query).first["count"]
  end

  def first
    loaded? ? to_a[0] : klass.new(DBConnection.execute(first_query).first)
  end

  def to_a
    load
    @arr
  end

  def load
    reload unless loaded?
    self
  end

  def reload
    @arr = klass.parse_all(DBConnection.execute(to_sql))
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

  def to_sql
    ["SELECT\n  #{klass.table_name}.*", from_str, where_str].join("\n")
  end

  private
  attr_accessor :klass, :options

  def first_query
    to_sql + "\nLIMIT 1"
  end

  def count_query
    ["SELECT\n  COUNT(*) AS count", from_str, where_str].join("\n")
  end

  def from_str
    @from_str ||= "FROM\n  #{klass.table_name}" + join_str
  end

  def where_str
    @where_str ||= "WHERE\n " + where_substr(options[:where_params])
  end

  def build_where_str(where_params)
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

  def add_single_condition_where_substr(key, value)
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