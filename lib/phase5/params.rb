require 'uri'

module Phase5
  class Params
    # use your initialize to merge params from
    # 1. query string
    # 2. post body
    # 3. route params
    def initialize(req, route_params = {})
      query_string_params =
        req.query_string ? parse_www_encoded_form(req.query_string) : Hash.new

      body_params =
        req.body ? parse_www_encoded_form(req.body) : Hash.new

      @params = query_string_params.merge(body_params).merge(route_params)
    end

    def [](key)
      @params[key.to_s]
    end

    def to_s
      @params.to_json.to_s
    end

    class AttributeNotFoundError < ArgumentError; end;

    private
    # this should return deeply nested hash
    # argument format
    # user[address][street]=main&user[address][zip]=89436
    # should return
    # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
    def parse_www_encoded_form(www_encoded_form)
      unnested_hash = URI.decode_www_form(www_encoded_form)

      unnested_hash.inject(Hash.new) do |nested_hash, (key, value)|
        key_sequence = parse_key(key)
        innermost_key = key_sequence.pop

        key_sequence.inject(nested_hash) do |inner_hash, inner_key|
          inner_hash[inner_key] ||= Hash.new
        end[innermost_key] = value

        nested_hash
      end
    end

    # this should return an array
    # user[address][street] should return ['user', 'address', 'street']
    def parse_key(key)
      key.split(/\]\[|\[|\]/)
    end
  end
end
