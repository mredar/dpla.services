require 'test_helper'

class TestJsonEtlProcess < ActiveSupport::TestCase
  def test_geonames_postal
    locations = ['United States', 'Minnesota', 'Minneapolis', 'Hennepin County']
    json = JsonEtl::Transform::Processors.geonames_postal(locations, {}, 'libsys')
    assert_equal({}, json)    
  end
end