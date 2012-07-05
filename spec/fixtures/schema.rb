# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120318055757) do

  create_table "flexi_model_collections", :force => true do |t|
    t.string 'name'
    t.string 'singular_label'
    t.string 'plural_label'
    t.string 'namespace'
    t.integer 'partition_id'

    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "flexi_model_collections", [:namespace, :name]
  add_index "flexi_model_collections", [:namespace, :name, :partition_id],
            name: 'index_ns_name_pi', unique: true

  create_table 'flexi_model_fields', :force => true do |t|
    t.string 'name'
    t.string 'singular_label'
    t.string 'plural_label'
    t.string 'namespace'
    t.integer 'partition_id'

    t.string 'field_type'
    t.text 'default_value'
  end

  add_index 'flexi_model_fields', [:namespace, :name]
  add_index 'flexi_model_fields', [:namespace, :name, :field_type]
  add_index 'flexi_model_fields', [:namespace, :name, :field_type, :partition_id],
            unique: true,
            name: 'index_ns_name_ft_pi'

  create_table 'flexi_model_collections_fields', :force => true, :id => false do |t|
    t.integer 'collection_id'
    t.integer 'field_id'
  end

  add_index 'flexi_model_collections_fields', [:collection_id]
  add_index 'flexi_model_collections_fields', [:field_id]

  create_table 'flexi_model_records', :force => true do |t|
    t.integer 'collection_id'
    t.string 'namespace'
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index 'flexi_model_records', [:namespace, :collection_id]

  create_table 'flexi_model_values', :force => true do |t|
    t.integer 'record_id'
    t.integer 'field_id'
    t.boolean 'bool_value'
    t.integer 'int_value'
    t.decimal 'dec_value'
    t.string 'str_value'
    t.text 'txt_value'
    t.datetime 'dt_value'
  end

  add_index 'flexi_model_values', [:record_id, :field_id]

end
