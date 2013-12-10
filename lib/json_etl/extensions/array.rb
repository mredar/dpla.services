class Array
  def to_keyed_hash(key)
    keyed_hash = {}
    self.each do |item|
      if (item[key])
        keyed_hash[item[key]] = item
      end
    end
    keyed_hash
  end  

  # Recurse through a nested array, remove all the nils and empty arrays
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
end