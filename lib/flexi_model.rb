require 'flexi_model/fields'
require 'flexi_model/callbacks'
require 'flexi_model/validations'
require 'flexi_model/association'
require 'flexi_model/scope'

module FlexiModel
  extend ActiveSupport::Concern

  included do
    class_eval <<-RUBY
      attr_accessor :_id, :_record
    RUBY
  end

  include FlexiModel::Fields
  include FlexiModel::Callbacks
  include FlexiModel::Validations

  if defined?(ActiveRecord)
    require 'flexi_model/ar_models'
    require 'flexi_model/ar_persistence'
    require 'flexi_model/ar_queryable'

    include FlexiModel::ArModels
    include FlexiModel::ArPersistence
    include FlexiModel::ArQueryable
  else
    raise "No Active Record Found"
  end

  include FlexiModel::Association
  include FlexiModel::Scope

end