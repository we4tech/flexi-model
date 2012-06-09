module FlexiModel
  module ArModels
    class Record < ActiveRecord::Base
      self.table_name = 'flexi_model_records'

      belongs_to :collection
      has_many :values, :dependent => :destroy

      scope :by_namespace, lambda { |n| where(namespace: n) }

      def value_of(field_name)
        values.select{|v| v.field.name.downcase == field_name.downcase}.first
      end
    end
  end
end