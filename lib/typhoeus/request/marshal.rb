module Typhoeus
  class Request

    # This module contains custom serializer.
    module Marshal

      # Return the important data needed to serialize this Request, except the
      # `on_complete`, `on_success`, and `on_failure` handlers, since they cannot be marshalled.
      def marshal_dump
        callbacks = %w(@on_complete @on_success @on_failure)
        (instance_variables - callbacks - callbacks.map(&:to_sym)).map do |name|
          [name, instance_variable_get(name)]
        end
      end

      # Load.
      def marshal_load(attributes)
        attributes.each { |name, value| instance_variable_set(name, value) }
      end
    end
  end
end