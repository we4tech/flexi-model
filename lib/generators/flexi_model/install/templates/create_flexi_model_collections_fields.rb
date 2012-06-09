class CreateFlexiModelCollectionsFields < ActiveRecord::Migration
  def change
    create_table 'flexi_model_collections_fields', :force => true do |t|
      t.integer 'collection_id'
      t.integer 'field_id'
    end

    add_index 'flexi_model_collections_fields', [:collection_id]
    add_index 'flexi_model_collections_fields', [:field_id]
  end
end
