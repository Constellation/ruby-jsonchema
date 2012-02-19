# vim: fileencoding=utf-8

module JSON
  class Schema
    VERSION = '2.0.1'
    class ValueError < Exception;end
    class Undefined;end
    TypesMap = {
      "string"  => String,
      "integer" => [Integer, Fixnum],
      "number"  => [Integer, Float, Fixnum, Numeric],
      "boolean" => [TrueClass, FalseClass],
      "object"  => Hash,
      "array"   => Array,
      "null"    => NilClass,
      "any"     => nil
    }
    TypesList = [String, Integer, Float, Fixnum, Numeric, TrueClass, FalseClass, Hash, Array, NilClass]
    def initialize interactive
      @interactive = interactive
      @refmap = {}
    end
    
    def keys
      @keys ||= []
    end
    
    def key_path
      keys.reject{|k| k == 'self'}.join(" > ")
    end
    
    def check_property value, schema, key, parent
      if schema
        keys.push key
#        if @interactive && schema['readonly']
#          raise ValueError, "#{key_path} is a readonly field , it can not be changed"
#        end

        if schema['id']
          @refmap[schema['id']] = schema
        end

        if schema['extends']
          check_property(value, schema['extends'], key, parent)
        end

        if value == Undefined
          unless schema['optional']
            raise ValueError, "#{key_path}: is missing and it is not optional"
          end

          # default
          if @interactive && !parent.include?(key) && !schema['default'].nil?
            unless schema["readonly"]
              parent[key] = schema['default']
            end
          end
        else

          # type
          if schema['type']
            check_type(value, schema['type'], key, parent)
          end

          # disallow
          if schema['disallow']
            flag = true
            begin
              check_type(value, schema['disallow'], key, parent)
            rescue ValueError
              flag = false
            end
            raise ValueError, "#{key_path}: disallowed value was matched" if flag
          end

          unless value.nil?
            if value.kind_of? Array
              if schema['items']
                if schema['items'].kind_of?(Array)
                  schema['items'].each_with_index {|val, index|
                    check_property(undefined_check(value, index), schema['items'][index], index, value)
                  }
                  if schema.include?('additionalProperties')
                    additional = schema['additionalProperties']
                    if additional.kind_of?(FalseClass)
                      if schema['items'].size < value.size
                        raise ValueError, "#{key_path}: There are more values in the array than are allowed by the items and additionalProperties restrictions."
                      end
                    else
                      value.each_with_index {|val, index|
                        check_property(undefined_check(value, index), schema['additionalProperties'], index, value)
                      }
                    end
                  end
                else
                  value.each_with_index {|val, index|
                    check_property(undefined_check(value, index), schema['items'], index, value)
                  }
                end
              end
              if schema['minItems'] && value.size < schema['minItems']
                raise ValueError, "#{key_path}: There must be a minimum of #{schema['minItems']} in the array"
              end
              if schema['maxItems'] && value.size > schema['maxItems']
                raise ValueError, "#{key_path}: There must be a maximum of #{schema['maxItems']} in the array"
              end
            elsif schema['properties']
              check_object(value, schema['properties'], schema['additionalProperties'])
            elsif schema.include?('additionalProperties')
              additional = schema['additionalProperties']
              unless additional.kind_of?(TrueClass)
                if additional.kind_of?(Hash) || additional.kind_of?(FalseClass)
                  properties = {}
                  value.each {|k, val|
                    if additional.kind_of?(FalseClass)
                      raise ValueError, "#{key_path}: Additional properties not defined by 'properties' are not allowed in field '#{k}'"
                    else
                      check_property(val, schema['additionalProperties'], k, value)
                    end
                  }
                else
                  raise ValueError, "#{key_path}: additionalProperties schema definition for field '#{}' is not an object"
                end
              end
            end

            if value.kind_of?(String)
              # pattern
              if schema['pattern'] && !(value =~ Regexp.new(schema['pattern']))
                raise ValueError, "#{key_path}: does not match the regex pattern #{schema['pattern']}"
              end

              strlen = value.split(//).size
              # maxLength
              if schema['maxLength'] && strlen > schema['maxLength']
                raise ValueError, "#{key_path}: may only be #{schema['maxLength']} characters long"
              end

              # minLength
              if schema['minLength'] && strlen < schema['minLength']
                raise ValueError, "#{key_path}: must be at least #{schema['minLength']} characters long"
              end
            end

            if value.kind_of?(Numeric)

              # minimum + minimumCanEqual
              if schema['minimum']
                minimumCanEqual = schema.fetch('minimumCanEqual', Undefined)
                if minimumCanEqual == Undefined || minimumCanEqual
                  if value < schema['minimum']
                    raise ValueError, "#{key_path}: must have a minimum value of #{schema['minimum']}"
                  end
                else
                  if value <= schema['minimum']
                    raise ValueError, "#{key_path}: must have a minimum value of #{schema['minimum']}"
                  end
                end
              end

              # maximum + maximumCanEqual
              if schema['maximum']
                maximumCanEqual = schema.fetch('maximumCanEqual', Undefined)
                if maximumCanEqual == Undefined || maximumCanEqual
                  if value > schema['maximum']
                    raise ValueError, "#{key_path}: must have a maximum value of #{schema['maximum']}"
                  end
                else
                  if value >= schema['maximum']
                    raise ValueError, "#{key_path}: must have a maximum value of #{schema['maximum']}"
                  end
                end
              end

              # maxDecimal
              if schema['maxDecimal'] && schema['maxDecimal'].kind_of?(Numeric)
                if value.to_s =~ /\.\d{#{schema['maxDecimal']+1},}/
                  raise ValueError, "#{key_path}: may only have #{schema['maxDecimal']} digits of decimal places"
                end
              end

            end

            # enum
            if schema['enum']
              unless(schema['enum'].detect{|enum| enum == value })
                raise ValueError, "#{key_path}: does not have a value in the enumeration #{schema['enum'].join(", ")}"
              end
            end

            # description
            if schema['description'] && !schema['description'].kind_of?(String)
              raise ValueError, "#{key_path}: The description for field '#{value}' must be a string"
            end

            # title
            if schema['title'] && !schema['title'].kind_of?(String)
              raise ValueError, "#{key_path}: The title for field '#{value}' must be a string"
            end

            # format
            if schema['format']
            end

          end
        end
        keys.pop
      end
    end

    def check_object value, object_type_def, additional
      if object_type_def.kind_of? Hash
        if !value.kind_of?(Hash) || value.kind_of?(Array)
          raise ValueError, "an object is required"
        end

        object_type_def.each {|key, odef|
          if key.index('__') != 0
            check_property(undefined_check(value, key), odef, key, value)
          end
        }
      end
      value.each {|key, val|
        if key.index('__') != 0 && object_type_def && !object_type_def[key] && additional == false
          raise ValueError, "The property #{key_path} > #{key} is not defined in the schema and the schema does not allow additional properties"
        end
        requires = object_type_def && object_type_def[key] && object_type_def[key]['requires']
        if requires && !value.include?(requires)
          raise ValueError, "The presence of the property #{key_path} > #{key} requires that #{requires} also be present"
        end
        if object_type_def && object_type_def.kind_of?(Hash) && !object_type_def.include?(key)
          check_property(val, additional, key, value)
        end
        if !@interactive && val && val['$schema']
          check_property(val, val['$schema'], key, value)
        end
      }
    end

    def check_type value, type, key, parent
      converted_fieldtype = convert_type(type)
      if converted_fieldtype
        if converted_fieldtype.kind_of? Array
          datavalid = false
          converted_fieldtype.each do |t|
            begin
              check_type(value, t, key, parent)
              datavalid = true
              break
            rescue ValueError
              next
            end
          end
          unless datavalid
            raise ValueError, "#{key_path}: #{value.class} value found, but a #{type} is required"
          end
        elsif converted_fieldtype.kind_of? Hash
          check_property(value, type, key, parent)
        else
          unless value.kind_of? converted_fieldtype
            raise ValueError, "#{key_path}: #{value.class} value found, but a #{type} is required"
          end
        end
      end
    end

    def undefined_check value, key
      value.fetch(key, Undefined)
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

    def validate instance, schema
      @tree = {
        'self' => instance
      }
      if schema
        check_property(instance, schema, 'self', @tree)
      elsif instance && instance['$schema']
        # self definition schema
        check_property(instance, instance['$schema'], 'self', @tree)
      end
      return @tree['self']
    end

    class << self
      def validate data, schema=nil, interactive=true
        validator = JSON::Schema.new(interactive)
        validator.validate(data, schema)
      end
    end
  end
end

