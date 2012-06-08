module FlexiModel
  class RecordValue < ActiveRecord::Base
    belongs_to :record
    belongs_to :field

  end
end