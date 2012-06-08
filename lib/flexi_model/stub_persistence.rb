module FlexiModel
  module Persistence
    extend ActiveSupport::Concern

    module ClassMethods
      def destroy_all; end
      def delete_all; end

      def count; 0 end
      def length; 0 end
    end

    # Persist data in AR backend or Mongoid backend
    def save; end
    def create; end
    def update_attributes; end
    def update_attribute; end
    def destroy; end
    def destroy_all; end
    def delete_all; end
    def count; end
    def length; end
  end
end