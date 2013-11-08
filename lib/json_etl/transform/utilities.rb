require 'open-uri'

module JsonEtl
  module Transform
    module Utilities

      # Make utility methods directly callable
      module_function

      def add_lookup_keys(field_name, hash)
        keyed_hash = {}
        hash.each do |item|
          if (item[field_name])
            keyed_hash[item[field_name]] = item
          end
        end
        keyed_hash
      end

      # Recursively apply a label to each item in an array
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

      # Recurse through a nested array, remove all the nils and empty arrays
      def deep_clean(arr)
        
        # Remove all the nils at the base level of the array
        arr.compact!
        arr.each_index do |i|
          if (arr[i].is_a?(Array))
            # Remove nils
            arr[i].compact!
            # If an array only had nils, remove it
            if (arr[i].empty?)
              arr.delete_at(i)
              # Deleting changes the index, start over
              # So that we get the remaining elements at this level
              deep_clean(arr)
            end
            #if we have a non-empty array, iterate over and clean it
            if (arr[i].is_a?(Array))
              deep_clean(arr[i])
            end
          end
        end
      end


      # Traverse a hash to a location specified by a slash delinieated string
      # e.g. "result/OAI_PMH/ListRecords/record"
      def fetch_slice(path, set)
        if path == '/'
            set
        else
          # Grab and strip the predicate from the path
          predicate =  /\[.*\]/.match(path)
          if (predicate)
            path = path.dup
            path.gsub!(predicate[0], '')
          end
          set = path.split("/").inject(set) {|set, key| set[key] }
          # Now use the stripped predicate to filter the result
          if (!predicate.nil?)
            set = filter_by_predicate(set, predicate[0])
          end
          set
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