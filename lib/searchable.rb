require_relative 'db_connection'

module Searchable
  def where(params)
    where_str = params.keys.map{ |key| "#{key} = ?"}.join(" AND ")

    arr = DBConnection.execute(<<-SQL, *params.values)
          SELECT
            *
          FROM
            #{table_name}
          WHERE
            #{where_str}
        SQL

    parse_all(arr)
  end
end
