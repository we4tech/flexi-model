class CreateFlexiModelFields < ActiveRecord::Migration
  def change
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
    add_index 'flexi_model_fields', [:namespace, :name, :field_type, :partition_id], name: 'index_ns_name_ft_pi'
  end
end
