require 'test_helper'


class TestValidator < ActiveSupport::TestCase
  include JsonEt::Transform::Utilities

  def test_diff_with_dpla
    params = {}
    record = JSON.parse(load_fixture('record'))
    record_diff_fixture = load_fixture('record_diff')
    params[:dpla_api_key] = APP_CONFIG['dpla']['api_key']
    params[:records] = [record]
    params[:dpla_query_params] = CGI::escape('isShownAt=http://reflections.mndigital.org/u?/swede,4')
    validator = Validator.new
    record_diff = validator.diff(params)
    filepath = File.join(Rails.root, "tmp", "tests", "record_diff.json")
    File.open(filepath, "w") do |f|
      f.puts record_diff
    end
    assert_equal(record_diff_fixture, record_diff)
  end

  def load_fixture(name)
    e = File.open(File.join(File.dirname(__FILE__), "fixtures", "#{name}.json"), 'r')
    extraction = e.read
    e.close
    return extraction
  end

end
