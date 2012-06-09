class CreateFlexiModelValues < ActiveRecord::Migration
  def change
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

    add_index 'flexi_model_values', [:record_id]
    add_index 'flexi_model_values', [:field_id]

  end
end
