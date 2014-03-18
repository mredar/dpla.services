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
        if (value.respond_to?('match'))
          match = value.match("#{pattern}")
          if (defined?(match[0]))
            match[0]
          end
        else
          value
        end
      end

      def get_field_values(config, record)
        vals = []
        if config['value']
          vals << config['value']
        else
          config['origins'].each do |origin|
            data = record.fetch_slice(origin['path'])
            if data && !data.is_a?(Enumerable)
              # Allow clients to wrap each result to make regexing easier
              # if they want manipulate multiple paths in different ways
              vals << "#{origin['prefix']}#{data}#{origin['suffix']}"
            else
              vals << data
            end
          end
        end
        # If they only gave us one path, just use that.
        (vals.count > 1) ? vals : vals.pop
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
        path.split("/").inject(self) do |item, key|
          # Grab and strip the predicate from the path
          preds = /(.*)\[(.*)\]/.match(key)
          if (preds)
            # Right now, we can only return a specific value
            # Xpath supports expressions etc (e.g. [last()], [last()-1])
            # I initially tried JSONpath, but it was an abysmal performer
            # So, I have opted to support a subset of xpath's features
            item = fetch_predicate(item, preds)
          else
            if item.is_a?(Hash)
              if (!item[key])
                return nil
              else
                item[key]
              end
            else
              # If we don't have a hash at this point, just return the value
              item
            end
          end
        end
      end
    rescue Exception => e
      service_log.error("Tried to fetch slice for path `#{path}` from `#{self}` and failed. Error message: #{e.message}")
      raise e
    end
  end

  # Start by supporting a few XPath predicates.
  def fetch_predicate(item, matches)
    pred = matches[2]
    data = item[matches[1]]
    if data.is_a?(Array)
      if pred == 'first()'
        data.first
      elsif pred == 'last()'
        data.last
      else
        data[pred.to_i]
      end
    end
  end
end