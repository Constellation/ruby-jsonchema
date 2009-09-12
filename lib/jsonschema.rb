# vim: fileencoding=utf-8

module JSON
  class Schema
    VERSION = '1.0.0'
    class ValueError < Exception;end
    TypesMap = {
      "string"  => String,
      "integer" => Integer,
      "number"  => [Integer, Float],
      "boolean" => [TrueClass, FalseClass],
      "object"  => Hash,
      "array"   => Array,
      "null"    => NilClass,
      "any"     => nil
    }
    TypesList = [String, Integer, Float, TrueClass, FalseClass, Hash, Array, NilClass]
    DefaultSchema = {
      "id"                    => nil,
      "type"                  => nil,
      "properties"            => nil,
      "items"                 => nil,
      "optional"              => false,
      "additionalProperties" => nil,
      "requires"              => nil,
      "identity"              => nil,
      "minimum"               => nil,
      "maximum"               => nil,
      "minItems"             => nil,
      "maxItems"             => nil,
      "pattern"               => nil,
      "maxLength"            => nil,
      "minLength"            => nil,
      "enum"                  => nil,
      "options"               => nil,
      "readonly"              => nil,
      "title"                 => nil,
      "description"           => nil,
      "format"                => nil,
      "default"               => nil,
      "transient"             => nil,
      "maxDecimal"           => nil,
      "hidden"                => nil,
      "disallow"              => nil,
      "extends"               => nil
    }
    def initialize interactive=true
      @interactive = interactive
      @refmap = {}
    end

    def validate data, schema
      @refmap = {
        '$' => schema
      }
      _validate(data, schema)
    end

    private
    def validate_id x, fieldname, schema, id=nil
      unless id.nil?
        if id == '$'
          raise ValueError, "Reference id for field '#{fieldname}' cannot equal '$'"
        end
        @refmap[id] = schema
      end
      return x
    end

    def validate_type x, fieldname, schema, fieldtype=nil
      converted_fieldtype = convert_type(fieldtype)
      fieldexists = true
      begin
        val = x.fetch(fieldname)
      rescue IndexError
        fieldexists = false
      ensure
        val = x[fieldname]
      end
      if converted_fieldtype && fieldexists
        if converted_fieldtype.kind_of? Array
          datavalid = false
          converted_fieldtype.each do |type|
            begin
              validate_type(x, fieldname, type, type)
              datavalid = true
              break
            rescue ValueError
              next
            end
          end
          unless datavalid
            raise ValueError, "Value #{val} for field '#{fieldname}' is not of type #{fieldtype}"
          end
        elsif converted_fieldtype.kind_of? Hash
          begin
            __validate(fieldname, x, converted_fieldtype)
          rescue ValueError => e
            raise e
          end
        else
          unless val.kind_of? converted_fieldtype
            raise ValueError, "Value #{val} for field '#{fieldname}' is not of type #{fieldtype}"
          end
        end
      end
      return x
    end

    def validate_properties x, fieldname, schema, properties=nil
      if !properties.nil? && x[fieldname]
        value = x[fieldname]
        if value
          if value.kind_of? Hash
            if properties.kind_of? Hash
              properties.each do |key, val|
                __validate(key, value, val)
              end
            else
              raise ValueError, "Properties definition of field '#{fieldname}' is not an object"
            end
          end
        end
      end
      return x
    end

    def validate_items x, fieldname, schema, items=nil
      if !items.nil? && x[fieldname]
        value = x[fieldname]
        unless value.nil?
          if value.kind_of? Array
            if items.kind_of? Array
              if items.size == value.size
                items.each_with_index do |item, index|
                  begin
                    validate(value[index], item)
                  rescue ValueError => e
                    raise ValueError, "Failed to validate field '#{fieldname}' list schema: #{e.message}"
                  end
                end
              else
                raise ValueError, "Length of list #{value} for field '#{fieldname}' is not equal to length of schema list"
              end
            elsif items.kind_of? Hash
              value.each do |val|
                begin
                  _validate(val, items)
                rescue ValueError => e
                  raise ValueError, "Failed to validate field '#{fieldname}' list schema: #{e.message}"
                end
              end
            else
              raise ValueError, "Properties definition of field '#{fieldname}' is not a list or an object"
            end
          end
        end
      end
      return x
    end

    def validate_optional x, fieldname, schema, optional=false
      if !x.include?(fieldname) && !optional
        raise ValueError, "Required field '#{fieldname}' is missing"
      end
      return x
    end

    def validate_additionalProperties x, fieldname, schema, additional_properties=nil
      unless additional_properties.nil?
        if additional_properties.kind_of? TrueClass
          return x
        end
        value = x[fieldname]
        if additional_properties.kind_of?(Hash) || additional_properties.kind_of?(FalseClass)
          properties = schema["properties"]
          unless properties
            properties = {}
          end
          value.keys.each do |key|
            unless properties.include? key
              if additional_properties.kind_of? FalseClass
                raise ValueError, "Additional properties not defined by 'properties' are not allowed in field '#{fieldname}'"
              else
                __validate(key, value, additional_properties)
              end
            end
          end
        else
          raise ValueError, "additionalProperties schema definition for field '#{fieldname}' is not an object"
        end
      end
      return x
    end

    def validate_requires x, fieldname, schema, requires=nil
      if x[fieldname] && !requires.nil?
        unless x[requires]
          raise ValueError, "Field '#{requires}' is required by field '#{fieldname}'"
        end
      end
      return x
    end

    def validate_identity x, fieldname, schema, unique=false
      return x
    end

    def validate_minimum x, fieldname, schema, minimum=nil
      if !minimum.nil? && x[fieldname]
        value = x[fieldname]
        if value
          if (value.kind_of?(Integer) || value.kind_of?(Float)) && value < minimum
            raise ValueError, "Value #{value} for field '#{fieldname}' is less than minimum value: #{minimum}"
          elsif value.kind_of?(Array) && value.size < minimum
            raise ValueError, "Value #{value} for field '#{fieldname}' has fewer values than the minimum: #{minimum}"
          end
        end
      end
      return x
    end

    def validate_maximum x, fieldname, schema, maximum=nil
      if !maximum.nil? && x[fieldname]
        value = x[fieldname]
        if value
          if (value.kind_of?(Integer) || value.kind_of?(Float)) && value > maximum
            raise ValueError, "Value #{value} for field '#{fieldname}' is greater than maximum value: #{maximum}"
          elsif value.kind_of?(Array) && value.size > maximum
            raise ValueError, "Value #{value} for field '#{fieldname}' has more values than the maximum: #{maximum}"
          end
        end
      end
      return x
    end

    def validate_minItems x, fieldname, schema, minitems=nil
      if !minitems.nil? && x[fieldname]
        value = x[fieldname]
        if value
          if value.kind_of?(Array) && value.size < minitems
            raise ValueError, "Value #{value} for field '#{fieldname}' must have a minimum of #{minitems} items"
          end
        end
      end
      return x
    end

    def validate_maxItems x, fieldname, schema, maxitems=nil
      if !maxitems.nil? && x[fieldname]
        value = x[fieldname]
        if value
          if value.kind_of?(Array) && value.size > maxitems
            raise ValueError, "Value #{value} for field '#{fieldname}' must have a maximum of #{maxitems} items"
          end
        end
      end
      return x
    end

    def validate_pattern x, fieldname, schema, pattern=nil
      value = x[fieldname]
      if !pattern.nil? && value && value.kind_of?(String)
        p = Regexp.new(pattern)
        if !p.match(value)
          raise ValueError, "Value #{value} for field '#{fieldname}' does not match regular expression '#{pattern}'"
        end
      end
      return x
    end

    def validate_maxLength x, fieldname, schema, length=nil
      value = x[fieldname]
      if !length.nil? && value && value.kind_of?(String)
        # string length => 正規表現で分割して計測
        if value.split(//).size > length
          raise ValueError, "Length of value #{value} for field '#{fieldname}' must be less than or equal to #{length}"
        end
      end
      return x
    end

    def validate_minLength x, fieldname, schema, length=nil
      value = x[fieldname]
      if !length.nil? && value && value.kind_of?(String)
        if value.split(//).size < length
          raise ValueError, "Length of value #{value} for field '#{fieldname}' must be more than or equal to #{length}"
        end
      end
      return x
    end

    def validate_enum x, fieldname, schema, options=nil
      value = x[fieldname]
      if !options.nil? && value
        unless options.kind_of? Array
          raise ValueError, "Enumeration #{options} for field '#{fieldname}' is not a list type"
        end
        unless options.include? value
          raise ValueError, "Value #{value} for field '#{fieldname}' is not in the enumeration: #{options}"
        end
      end
      return x
    end

    def validate_options x, fieldname, schema, options=nil
      return x
    end

    def validate_readonly x, fieldname, schema, readonly=false
      return x
    end

    def validate_title x, fieldname, schema, title=nil
      if !title.nil? && !title.kind_of?(String)
        raise ValueError, "The title for field '#{fieldname}' must be a string"
      end
      return x
    end

    def validate_description x, fieldname, schema, description=nil
      if !description.nil? && !description.kind_of?(String)
        raise ValueError, "The description for field '#{fieldname}' must be a string"
      end
      return x
    end

    def validate_format x, fieldname, schema, format=nil
      return x
    end

    def validate_default x, fieldname, schema, default=nil
      if @interactive && !x.include?(fieldname) && !default.nil?
        unless schema["readonly"]
          x[fieldname] = default
        end
      end
      return x
    end

    def validate_transient x, fieldname, schema, transient=false
      return x
    end

    def validate_maxDecimal x, fieldname, schema, maxdecimal=nil
      value = x[fieldname]
      if !maxdecimal.nil? && value
        maxdecstring = value.to_s
        index = maxdecstring.index('.')
        if index && maxdecstring[(index+1)...maxdecstring.size].split(//u).size > maxdecimal
          raise ValueError, "Value #{value} for field '#{fieldname}' must not have more than #{maxdecimal} decimal places"
        end
      end
      return x
    end

    def validate_hidden x, fieldname, schema, hidden=false
      return x
    end

    def validate_disallow x, fieldname, schema, disallow=nil
      if !disallow.nil?
        begin
          validate_type(x, fieldname, schema, disallow)
        rescue ValueError
          return x
        end
        raise ValueError, "Value #{x[fieldname]} of type #{disallow} is disallowed for field '#{fieldname}'"
      end
      return x
    end

    def validate_extends x, fieldname, schema, extends=nil
      return x
    end

    def convert_type fieldtype
      if TypesList.include?(fieldtype) || fieldtype.kind_of?(Hash)
        return fieldtype
      elsif fieldtype.kind_of? Array
        converted_fields = []
        fieldtype.each do |subfieldtype|
          converted_fields << convert_type(subfieldtype)
        end
        return converted_fields
      elsif !fieldtype
        return nil
      else
        fieldtype = fieldtype.to_s
        if TypesMap.include?(fieldtype)
          return TypesMap[fieldtype]
        else
          raise ValueError, "Field type '#{fieldtype}' is not supported."
        end
      end
    end

    def __validate fieldname, data, schema
      if schema
        if !schema.kind_of?(Hash)
          raise ValueError, "Schema structure is invalid"
        end
        # copy
        new_schema = Marshal.load(Marshal.dump(schema))
        DefaultSchema.each do |key, val|
          new_schema[key] = val unless new_schema.include?(key)
        end
        new_schema.each do |key ,val|
          validatorname = "validate_"+key
          begin
            __send__(validatorname, data, fieldname, schema, new_schema[key])
          rescue NoMethodError => e
            raise ValueError, "Schema property '#{e.message}' is not supported"
          end
        end
      end
      return data
    end

    def _validate data, schema
      __validate("_data", {"_data" => data}, schema)
    end

    class << self
      def validate data, schema, interactive=true
        validator = JSON::Schema.new(interactive)
        validator.validate(data, schema)
      end
    end
  end
end

