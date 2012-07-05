module FlexiModel
  module AttachmentField
    extend ActiveSupport::Concern

    module ClassMethods

      # Set filed definition which is used as attachment accessor.
      #
      # Ie. Paperclip exposes < attachment name > method over the host class.
      # Using this method we can hint admin panel that we have a field which
      # accepts file
      def attachment_field(name, options = { })
        options[:accessors] = false
        flexi_field name, :attachment, options
      end

      alias_method :_attachment, :attachment_field
    end
  end
end