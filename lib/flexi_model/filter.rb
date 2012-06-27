module FlexiModel
  module Filter
    extend ActiveSupport::Concern

    included do
      class_eval <<-CODE
        @@flexi_filters = {}
        cattr_accessor :flexi_filters
      CODE
    end

    module ClassMethods
      # Define filter for scoping data
      #
      #   name - Set filter name
      #   options - Hash of options
      #     field_types - Define renderable field types
      #     field_values - Define initial field values procs
      #   proc - Set lambda for the specific filter
      #
      # Example -
      #
      #   class Category
      #     include FlexiModel
      #     filter :by_name, {}, lambda { |param1, param2| ... }
      #   end
      #
      def flexi_filter(name, options = {}, &proc)
        raise "No lambda is defined for scope :#{name}" if proc.nil?

        accepted_params = proc.parameters.map(&:last)

        self.flexi_filters[name.to_sym] = {
            param_keys: accepted_params,
            options: options,
            proc: proc
        }

        _define_filter_method(name)
      end

      def _define_filter_method(name)
        self.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def self.#{name.to_s}(args = {})
            _filter_params = self.flexi_filters[:#{name.to_s}]
            _values = _filter_params[:param_keys].map{ |k| args[k] }

            _inst = args[:instance] || self
            _block = _filter_params[:proc]
            _inst.instance_exec(*_values, &_block)
          end

          def #{name.to_s}(args = {})
            args[:instance] = self
            self.class.#{name.to_s}(args)
          end
        CODE
      end
    end
  end
end