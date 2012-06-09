module FlexiModel
  module Validations
    extend ActiveSupport::Concern

    included do
      if defined?(ActiveModel)
        include ActiveModel
        include ActiveModel::Validations
      end
    end
  end

  def create(options = { })
    if perform_validation(options)
      super
    else
      self
    end
  end

  def update(options = { })
    if perform_validation(options)
      super
    else
      self
    end
  end

  def perform_validation(options = { })
    if options[:validate].nil? || options[:validate]
      valid?
    else
      true
    end
  end

end