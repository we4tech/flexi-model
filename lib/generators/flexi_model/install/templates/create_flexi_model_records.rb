class CreateFlexiModelRecords < ActiveRecord::Migration
  def change
    create_table 'flexi_model_records', :force => true do |t|
      t.integer 'collection_id'
      t.string 'namespace'
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index 'flexi_model_records', [:namespace, :collection_id]
  end
end
