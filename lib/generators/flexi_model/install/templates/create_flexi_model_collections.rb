class CreateFlexiModelCollections < ActiveRecord::Migration
  def change
    create_table "flexi_model_collections" do |t|
      t.string 'name'
      t.string 'singular_label'
      t.string 'plural_label'
      t.string 'namespace'
      t.integer 'partition_id'

      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "flexi_model_collections", [:namespace, :name]
    add_index "flexi_model_collections", [:namespace, :name, :partition_id], name: 'index_ns_name_pi'
  end
end
