class Hash
  # Traverse a hash to a location specified by a slash delinieated string
  # e.g. "result/OAI_PMH/ListRecords/record"
  def fetch_slice(path)
    if path == '/'
        self
    else
      # Grab and strip the predicate from the path
      predicate =  /\[.*\]/.match(path)
      if (predicate)
        path = path.dup
        path.gsub!(predicate[0], '')
      end
      out = path.split("/").inject(self) {|hash, key| hash[key] }
      # Now use the stripped predicate to filter the result
      if (!predicate.nil?)
        out = filter_by_predicate(self, predicate[0])
      end
      out
    end
  end
end