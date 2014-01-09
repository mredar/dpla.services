require 'open-uri'

module JsonEt
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

      # Create a hash from a slash delimited path and set field_name and field_value
      # as the deepest elements in the larger hash
      def field_hash_from_path(path, field_value)
        path.split("/").reverse.inject(field_value) {|memo, key| (!key) ? memo : { key => memo } }
      end
    end
  end
end


class Array

  # Remove nils from flat or nested array
  def deep_clean
    # Remove all the nils at the base level of the array
    self.compact!
    self.each_index do |i|
      if self[i].is_a?(Array)
        # Remove nils
        self[i].compact!
        # If an array only had nils, remove it
        if (self[i].empty?)
          self.delete_at(i)
          # So that we get the remaining elements at this level
          self.deep_clean
        end
        #if we have a non-empty array, iterate over and clean it
        if self[i].is_a?(Array)
          self[i].deep_clean
        end
      end
    end
  end

  # Take an array of hashes and return a hash indexed by the value
  # of one of its elements. Useful to creat lookup hashes from metadata
  # enrichements, like OAI collection "setSpec" fields.
  # e.g.
  # books = [{'identifier' => '123sdhh12123', 'title' => '1984'}, {'identifier' => '12323ljsdf', 'title' => 'Wool'}]
  # books.to_keyed_hash('identifier')
  # > {'123sdhh12123' => {'identifier' => '123sdhh12123', 'title' => '1984'}, '12323ljsdf' => {'identifier' => '12323ljsdf', 'title' => 'Wool'}}
  def to_keyed_hash(key_field_name)
    lookup = {}
    self.each do |record|
      if (key = record[key_field_name])
        lookup[key] = record
      end
    end
    lookup
  end

  # Grab an element off of an array based on an xpath predicate
  # For now, we only support index numbers
  def filter_by_predicate(predicate)
    pred = predicate.gsub(/\[|\]/, '')
    if (!pred.nil?)
      # We have an index number if none of these characters appear
      if (/[a-z()'']/ =~ pred).nil?
        pred = Integer(pred)
        out = self[pred]
      end
    end
    out
  end
end

class Hash
  include ServiceLog

  # Returns a value at the end of a path
  # Values returned can be ov any data type
  # e.g.
  #   d = {"foo"=>"bar", "baz"=>{"bat"=>"bang"}, "level"=>5, 'vals' => ['first', 'second']}
  #   p = 'baz'
  #   d.fetch_slice(p)
  # => {"bat"=>"bang"}
  #   p = 'baz/bat'
  #   d.fetch_slice(p)
  # => bang (String)
  #   p = 'baz/bat/bang'
  #   d.fetch_slice(p)
  # => bang (String)
  #   p = 'level'
  #   d.fetch_slice(p)
  # => 5 (Fixnum)
  #   p = 'vals'
  #   d.fetch_slice(p)
  # => first second (Array)
  #
  # Xpath predicates are supported, currently only for arrays
  #
  # e.g.
  #   p = 'vals[1]'
  #   d.fetch_slice(p)
  # => first (String)
  #
  def fetch_slice(path)
    begin
      out = {}
      if path == '/'
          self
      else
        # Grab and strip the predicate from the path
        path.split("/").inject(self) do |item, key|
          pred = /\[.*\]/.match(key)
          if (!pred.nil?)
            # Right now, we can only return a specific value
            # Xpath supports expressions etc (e.g. [last()], [last()-1])
            # I initially tried JSONpath, but it was an abysmal performer
            # So, I have opted to support a subset of xpath's features
            item = fetch_predicate(item, pred[0].gsub(/\[|\]/, ''))
          else
            item[key]
          end
        end
      end
    rescue Exception => e
      service_log.error("Tried to fetch slice for path #{path} from #{self} and failed. Sorry, boss. I'm a horrible computer. Error message: {e.message}")
      raise e
    end
  end

  # Start by supporting a few XPath predicates
  def fetch_predicate(array, pred)
    if pred == 'first()'
      array.first
    elsif pred == 'last()'
      array.last
    else
      array[pred.to_i]
    end
  end
end