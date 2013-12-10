require 'open-uri'

module JsonEtl
  module Transform
    module Utilities

      # Make utility methods directly callable
      module_function

      # Recursively apply a label to each item in an array,
      # if it is an array
      def apply_labels(values, label)
        values.map do |item|
          if (item.is_a?(Array))
            apply_labels(item, label)
          else
            { label => item }
          end
        end
      end

      # Recurse through an array, replace values with values
      # that match a given pattern
      # TODO: move the array test out of this method
      def fetch_values(values, pattern)
        if (values.is_a?(Array))
          values.map do |item|
            if (item.is_a?(Array))
              fetch_values(item, pattern)
            else
              matched_value(item, pattern)
            end
          end
        else
          matched_value(values, pattern)
        end
      end

      # Convenience method to return a regex matched value
      # TODO: move the string test out of this method      
      def matched_value(value, pattern)
        # If we get something other than a string at this point, punt
        if (value.is_a?(String))
          match = value.match("#{pattern}")
          if (defined?(match[0])) 
            match[0]
          end
        else
          value
        end
      end

      # Support xpath predicates
      # For now, we only support index numbers
      def filter_by_predicate(values, predicate)
        pred = predicate.gsub(/\[|\]/, '')
        if (!pred.nil?)
          # We have an index number if none of these characters appear
          if (/[a-z()'']/ =~ pred).nil?
            pred = Integer(pred)
            values = values[pred]
          end
        end
        values
      end

      # Create a hash from a slash delimited path and set field_name and field_value
      # as the deepest elements in the larger hash
      def field_hash_from_path(path, field_name, field_value)
        path.split("/").reverse.inject({field_name => field_value}) {|memo, key| (!key) ? memo : { key => memo } }
      end
    end
  end
end