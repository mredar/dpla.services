require 'yajl/json_gem'
require 'open-uri'

module JsonEt
  module Validate
    class Differ
      include ServiceLog
      include JsonEt::Transform::Utilities

      def path_compare(a, b, paths)
        diffs = {}
        diffs['fields'] = {}
        diffs['records'] = []
        paths.each do |path|
          seq1 = a.fetch_slice(path)
          seq2 = (b.is_a?(Hash)) ? b.fetch_slice(path) : nil
          diffs['fields'][path] = [seq1, seq2]
        end
        diffs['records'] << a
        diffs['records'] << b

        JSON.pretty_generate(diffs)
      end
    end
  end
end