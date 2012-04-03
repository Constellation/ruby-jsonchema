require 'test/unit'
require 'open-uri'
require 'pp'
require File.dirname(__FILE__) + '/../lib/jsonschema'

class JSONSchemaTest < Test::Unit::TestCase
  def test_self_schema
    data1 =  {
      "$schema"=> {
          "properties"=> {
              "name"=> {
                  "type"=> "string"
              },
              "age" => {
                  "type"=> "integer",
                  "maximum"=> 125,
              }
          }
      },
      "name" => "John Doe",
      "age"  => 30,
      "type" => "object"
    }
    assert_nothing_raised{
      JSON::Schema.validate(data1)
    }
    data2 =  {
      "$schema"=> {
          "properties"=> {
              "name"=> {
                  "type"=> "integer"
              },
              "age" => {
                  "type"=> "integer",
                  "maximum"=> 125,
              }
          }
      },
      "name" => "John Doe",
      "age"  => 30,
      "type" => "object"
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data2)
    }
    data3 =  {
      "$schema"=> {
          "properties"=> {
              "name"=> {
                  "type"=> "integer"
              },
              "age" => {
                  "type"=> "integer",
                  "maximum"=> 125,
              }
          }
      },
      "name" => "John Doe",
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3)
    }
  end

  def test_maximum
    schema1 = {
      "type" => "object",
       "properties" => {
        "prop01" => {
          "type" => "number",
          "maximum" => 10
        },
        "prop02" => {
          "type" => "integer",
          "maximum" => 20
        }
      }
    }
    data1 = {
      "prop01"=> 5,
      "prop02"=> 10
    }
    data2 = {
      "prop01"=> 10,
      "prop02"=> 20
    }
    data3 = {
      "prop01"=> 11,
      "prop02"=> 19
    }
    data4 = {
      "prop01"=> 9,
      "prop02"=> 21
    }
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema1)
    }
    schema2 = {
      "type" => "object",
       "properties" => {
        "prop01" => {
          "type" => "number",
          "maximum" => 10,
          "maximumCanEqual" => true
        },
        "prop02" => {
          "type" => "integer",
          "maximum" => 20,
          "maximumCanEqual" => false
        }
      }
    }
    data5 = {
      "prop01"=> 10,
      "prop02"=> 10
    }
    data6 = {
      "prop01"=> 10,
      "prop02"=> 19
    }
    data7 = {
      "prop01"=> 11,
      "prop02"=> 19
    }
    data8 = {
      "prop01"=> 9,
      "prop02"=> 20
    }
    assert_nothing_raised{
      JSON::Schema.validate(data5, schema2)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data6, schema2)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data7, schema2)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data8, schema2)
    }
  end

  def test_extends
    schema = {
      "type" => "object",
      "properties" => {
        "prop01" => {
          "type" => "number",
          "minimum" => 10
        },
        "prop02" => {}
      }
    }
    schema["properties"]["prop02"]["extends"] = schema["properties"]["prop01"]
    data1 = {
      "prop01"=> 21,
      "prop02"=> 21
    }
    data2 = {
      "prop01"=> 10,
      "prop02"=> 20
    }
    data3 = {
      "prop01"=> 9,
      "prop02"=> 21
    }
    data4 = {
      "prop01"=> 10,
      "prop02"=> 9
    }
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema)
    }
  end

  def test_minimum
    schema1 = {
      "type" => "object",
      "properties" => {
        "prop01" => {
          "type" => "number",
          "minimum" => 10
        },
        "prop02" => {
          "type" => "integer",
          "minimum" => 20
        }
      }
    }
    data1 = {
      "prop01"=> 21,
      "prop02"=> 21
    }
    data2 = {
      "prop01"=> 10,
      "prop02"=> 20
    }
    data3 = {
      "prop01"=> 9,
      "prop02"=> 21
    }
    data4 = {
      "prop01"=> 10,
      "prop02"=> 19
    }
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema1)
    }
    schema2 = {
      "type" => "object",
      "properties" => {
        "prop01" => {
          "type" => "number",
          "minimum" => 10,
          "minimumCanEqual" => false
        },
        "prop02" => {
          "type" => "integer",
          "minimum" => 19,
          "minimumCanEqual" => true
        }
      }
    }
    data5 = {
      "prop01"=> 11,
      "prop02"=> 19
    }
    data6 = {
      "prop01"=> 10,
      "prop02"=> 19
    }
    data7 = {
      "prop01"=> 11,
      "prop02"=> 18
    }
    assert_nothing_raised{
      JSON::Schema.validate(data5, schema2)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data6, schema2)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data7, schema2)
    }
  end

  def test_minItems
    schema1 = {
      "type" => "array",
      "minItems" => 4
    }
    schema2 = {
      "minItems" => 4
    }
    data1 = [1, 2, "3", 4.0]
    data2 = [1, 2, "3", 4.0, 5.00]
    data3 = "test"
    data4 = [1, 2, "3"]
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data3, schema2)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema2)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema2)
    }
  end

  def test_maxItems
    schema1 = {
      "type" => "array",
      "maxItems" => 4
    }
    schema2 = {
      "maxItems" => 4
    }
    data1 = [1, 2, "3", 4.0]
    data2 = [1, 2, "3"]
    data3 = "test"
    data4 = [1, 2, "3", 4.0, 5.00]
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data3, schema2)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema2)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema2)
    }
  end

  def test_minLength
    schema = {
      "minLength" => 4
    }
    data1 = "test"
    data2 = "string"
    data3 = 123
    data4 = [1, 2, "3"]
    data5 = "car"
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data3, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data4, schema)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data5, schema)
    }
  end
  def test_maxLength
    schema = {
      "maxLength" => 4
    }
    data1 = "test"
    data2 = "car"
    data3 = 12345
    data4 = [1, 2, "3", 4, 5]
    data5 = "string"
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data3, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data4, schema)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data5, schema)
    }
  end

  def test_maxDecimal
    schema = {
      "type" => "number",
      "maxDecimal" => 3
    }
    data1 = 10.20
    data2 = 10.204
    data3 = 10
    data4 = 10.04092
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data3, schema)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema)
    }
  end

  def test_properties
    schema = {
      "type"=>"object",
      "properties"=>{
        "prop01"=>{
          "type"=>"string",
        },
        "prop02"=>{
          "type"=>"number",
          "required"=>false
        },
        "prop03"=>{
          "type"=>"integer",
        },
        "prop04"=>{
          "type"=>"boolean",
        },
        "prop05"=>{
          "type"=>"object",
          "required"=>false,
          "properties"=>{
            "subprop01"=>{
              "type"=>"string",
            },
            "subprop02"=>{
              "type"=>"string",
              "required"=>true
            }
          }
        }
      }
    }
    data1 = {
      "prop01"=>"test",
      "prop02"=>1.20,
      "prop03"=>1,
      "prop04"=>true,
      "prop05"=>{
        "subprop01"=>"test",
        "subprop02"=>"test2"
      }
    }
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    data2 = {
      "prop01"=>"test",
      "prop02"=>1.20,
      "prop03"=>1,
      "prop04"=>true
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema)
    }
    data3 = {
      "prop02"=>1.60,
      "prop05"=>{
        "subprop01"=>"test"
      }
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema)
    }
  end

  def test_title
    schema1 = {
      "title"=>"My Title for My Schema"
    }
    schema2 = {
      "title"=>1233
    }
    data = "whatever"
    assert_nothing_raised{
      JSON::Schema.validate(data, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data, schema2)
    }
  end

  def test_requires
    schema = {
      "type"=>"object",
      "properties"=>{
        "prop01"=>{
          "type"=>"string",
        },
        "prop02"=>{
          "type"=>"number",
          "requires"=>"prop01"
        }
      }
    }
    data1 = {}
    data2 = {
      "prop01"=>"test",
      "prop02"=>2
    }
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema)
    }
    data3 = {
      "prop02"=>2
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema)
    }
  end

  def test_pattern
    schema = {
      "pattern"=>"^[A-Za-z0-9][A-Za-z0-9\.]*@([A-Za-z0-9]+\.)+[A-Za-z0-9]+$"
    }
    data1 = "my.email01@gmail.com"
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    data2 = 123
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema)
    }
    data3 = "whatever"
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema)
    }
  end

  def test_required
    schema = {
      "type"=>"object",
      "properties"=>{
        "prop01"=>{
          "type"=>"string"
        },
        "prop02"=>{
          "type"=>"number",
          "required"=>false
        },
        "prop03"=>{
          "type"=>"integer"
        },
        "prop04"=>{
          "type"=>"boolean",
          "required"=>true
        }
      }
    }
    data1 = {
      "prop01"=>"test",
      "prop03"=>1,
      "prop04"=>false
    }
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema)
    }
    data2 = {
      "prop02"=>"blah"
    }
    data3 = {
      "prop01"=>"blah"
    }
    data4 = {
      "prop01"=>"test",
      "prop03"=>1,
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data2, schema)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data4, schema)
    }
  end

  def test_default
    schema1 = {
      "properties"=>{
        "test"=>{
          "default"=>10
        },
      }
    }
    schema2 = {
      "properties"=>{
        "test"=>{
          "default"=>10,
          "readonly"=>true
        }
      }
    }
    data1 = {}
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema1)
    }
    assert_equal(10, data1["test"])

    data2 = {}
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema2)
    }
    assert_not_equal(10, data2["test"])

    data3 = {}
    assert_nothing_raised{
      JSON::Schema.validate(data3, schema1, true)
    }
    assert_equal(10, data3["test"])

    data4 = {}
    assert_nothing_raised{
      JSON::Schema.validate(data4, schema1, false)
    }
    assert_not_equal(10, data4["test"])
  end

  def test_description
    schema1 = {
      "description"=>"My Description for My Schema"
    }
    schema2 = {
      "description"=>1233
    }
    data = "whatever"
    assert_nothing_raised{
      JSON::Schema.validate(data, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data, schema2)
    }
  end

	def test_type
		# schema
		schema1 = {
			"type"=>[
				{
          "type"=>"array",
					"minItems"=>10
				},
				{
          "type"=>"string",
          "pattern"=>"^0+$"
				}
			]
		}
		data1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
		data2 = "0"
		data3 = 1203
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema1)
    }
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema1)
    }

    # integer phase
    [1, 89, 48, 32, 49, 42].each do |item|
			assert_nothing_raised{
				JSON::Schema.validate(item, {"type"=>"integer"})
			}
    end
    [1.2, "bad", {"test" => "blah"}, [32, 49], nil, true].each do |item|
			assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"type"=>"integer"})
      }
    end

    # string phase
    ["surrender?", "nuts!", "ok", "@hsuha", "\'ok?\'", "blah"].each do |item|
			assert_nothing_raised{
        JSON::Schema.validate(item, {"type"=>"string"})
      }
    end
    [1.2, 1, {"test" => "blah"}, [32, 49], nil, true].each do |item|
			assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"type"=>"string"})
      }
    end

    # number phase
    [1.2, 89.42, 48.5224242, 32, 49, 42.24324].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"type"=>"number"})
      }
    end
    ["bad", {"test"=>"blah"}, [32.42, 494242], nil, true].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"type"=>"number"})
      }
    end

    # boolean phase
    [true, false].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"type"=>"boolean"})
      }
    end
    [1.2, "False", {"test" => "blah"}, [32, 49], nil, 1, 0].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"type"=>"boolean"})
      }
    end

    # object phase
    [{"blah"=>"test"}, {"this"=>{"blah"=>"test"}}, {1=>2, 10=>20}].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"type"=>"object"})
      }
    end
    [1.2, "bad", 123, [32, 49], nil, true].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"type"=>"object"})
      }
    end

    # array phase
    [[1, 89], [48, {"test"=>"blah"}, "49", 42]].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"type"=>"array"})
      }
    end
    [1.2, "bad", {"test"=>"blah"}, 1234, nil, true].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"type"=>"array"})
      }
    end

    # null phase
      assert_nothing_raised{
      JSON::Schema.validate(nil, {"type"=>"null"})
    }
    [1.2, "bad", {"test"=>"blah"}, [32, 49], 1284, true].each do |item|
			assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"type"=>"null"})
      }
    end

    # any phase
    [1.2, "bad", {"test"=>"blah"}, [32, 49], nil, 1284, true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"type"=>"any"})
      }
    end

	end

  def test_items
    schema1 = {
      "type"=>"array",
      "items"=>{
        "type"=>"string"
      }
    }
    schema2 = {
      "type"=>"array",
      "items"=>[
        {"type"=>"integer"},
        {"type"=>"string"},
        {"type"=>"boolean"}
      ]
    }
    data1 = ["string", "another string", "mystring"]
    data2 = ["JSON Schema is cool", "yet another string"]
    assert_nothing_raised{
      JSON::Schema.validate(data1, schema1)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data2, schema1)
    }
    data3 = ["string", "another string", 1]
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data3, schema1)
    }
    data4 = [1, "More strings?", true]
    data5 = [12482, "Yes, more strings", false]
    assert_nothing_raised{
      JSON::Schema.validate(data4, schema2)
    }
    assert_nothing_raised{
      JSON::Schema.validate(data5, schema2)
    }
    data6 = [1294, "Ok. I give up"]
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data6, schema2)
    }
    data7 = [1294, "Ok. I give up", "Not a boolean"]
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(data7, schema2)
    }
  end

  def test_enum
    schema = {
      "enum"=>["test", true, 123, ["???"]]
    }
    ["test", true, 123, ["???"]].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, schema)
      }
    end
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate("unknown", schema)
    }
  end


  def test_additionalProperties
    schema1 = {
      "additionalProperties"=>{
        "type" => "integer"
      }
    }
    [1, 89, 48, 32, 49, 42].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate({"prop" => item}, schema1)
      }
    end
    [1.2, "bad", {"test"=>"blah"}, [32, 49], nil, true].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate({"prop" => item}, schema1)
      }
    end
    schema2 = {
      "properties" => {
        "prop1" => {"type" => "integer"},
        "prop2" => {"type" => "string" }
      },
      "additionalProperties" => {
        "type" => ["string", "number"]
      }
    }
    [1, "test", 48, "ok", 4.9, 42].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate({
          "prop1" => 123,
          "prop2" => "this is prop2",
          "prop3" => item
        }, schema2)
      }
    end
    [{"test"=>"blah"}, [32, 49], nil, true].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate({
          "prop1" => 123,
          "prop2" => "this is prop2",
          "prop3" => item
        }, schema2)
      }
    end
    schema3 = {
      "additionalProperties" => true
    }
    [1.2, 1, {"test"=>"blah"}, [32, 49], nil, true, "blah"].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate({"prop" => item}, schema3)
      }
    end
    schema4 = {
      "additionalProperties" => false
    }
    ["bad", {"test"=>"blah"}, [32.42, 494242], nil, true, 1.34].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate({"prop" => item}, schema4)
      }
    end
  end

  def test_disallow
    # multi phase
    schema = {"disallow"=>["null","integer","string"]}
    [nil, 183, "mystring"].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, schema)
      }
    end
    [1.2, {"test"=>"blah"}, [32, 49], true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, schema)
      }
    end

    # any phase
    [1.2, "bad", {"test"=>"blah"}, [32, 49], nil, 1284, true].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"disallow"=>"any"})
      }
    end

    # null phase
    assert_raise(JSON::Schema::ValueError){
      JSON::Schema.validate(nil, {"disallow"=>"null"})
    }
    [1.2, "bad", {"test"=>"blah"}, [32, 49], 1284, true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"disallow"=>"null"})
      }
    end

    # array phase
    [[1, 89], [48, {"test"=>"blah"}, "49", 42]].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"disallow"=>"array"})
      }
    end
    [1.2, "bad", {"test"=>"blah"}, 1234, nil, true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"disallow"=>"array"})
      }
    end

    # object phase
    [{"blah"=>"test"}, {"this"=>{"blah"=>"test"}}, {1=>2, 10=>20}].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"disallow"=>"object"})
      }
    end
    [1.2, "bad", 123, [32, 49], nil, true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"disallow"=>"object"})
      }
    end

    # boolean phase
    [true, false].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"disallow"=>"boolean"})
      }
    end
    [1.2, "False", {"test" => "blah"}, [32, 49], nil, 1, 0].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"disallow"=>"boolean"})
      }
    end

    # number phase
    [1.2, 89.42, 48.5224242, 32, 49, 42.24324].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"disallow"=>"number"})
      }
    end
    ["bad", {"test"=>"blah"}, [32.42, 494242], nil, true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"disallow"=>"number"})
      }
    end

    # integer phase
    [1, 89, 48, 32, 49, 42].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"disallow"=>"integer"})
      }
    end
    [1.2, "bad", {"test" => "blah"}, [32, 49], nil, true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"disallow"=>"integer"})
      }
    end

    # string phase
    ["surrender?", "nuts!", "ok", "@hsuha", "\'ok?\'", "blah"].each do |item|
      assert_raise(JSON::Schema::ValueError){
        JSON::Schema.validate(item, {"disallow"=>"string"})
      }
    end
    [1.2, 1, {"test" => "blah"}, [32, 49], nil, true].each do |item|
      assert_nothing_raised{
        JSON::Schema.validate(item, {"disallow"=>"string"})
      }
    end
  end
end

