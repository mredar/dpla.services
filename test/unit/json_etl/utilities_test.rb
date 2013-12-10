require 'test_helper'

class TestJsonEtlUtilities < ActiveSupport::TestCase


  def test_add_lookup_keys
    hash = {"is" => {"it" => {"caturday" => ['yes', 'no', 'kthksbai'], "a" => "cheesburger"}}}
    keyed = JsonEtl::Transform::Utilities.add_lookup_keys('caturday', 'is/it', hash)
    assert_equal(["yes", "no", "kthksbai"], keyed) 
  end
 
  def test_apply_label
    values = ["lol", "catus", ["resistence", "is", "furtail"]]
    labeled = JsonEtl::Transform::Utilities.apply_labels(values, 'lolcat')
    expected = [{"lolcat"=>"lol"}, {"lolcat"=>"catus"}, [{"lolcat"=>"resistence"}, {"lolcat"=>"is"}, {"lolcat"=>"furtail"}]]
    assert_equal(expected, labeled)      
  end

  def test_fetch_values
    vals = ["happy", "happy", "joy", "joy"]
    matches = JsonEtl::Transform::Utilities.fetch_values(vals, "happy")
    assert_equal(["happy", "happy", nil, nil], matches)    
  end

  def test_mached_value
    "ohai here's a test"
    match = JsonEtl::Transform::Utilities.matched_value("ohai here's a test", "test")
    assert_equal('test', match)
  end

  def test_deep_clean
    arrs = [
      { "expected" => [], "original" => [nil, nil, nil]},
      { "expected" => ["heck"], "original" => ["heck"]},      
      { "expected" => [["yeah!"]], "original" => [[nil, nil, nil], ["yeah!"]]},
      { "expected" => [["heck", "yeah!"]], "original" => [nil, nil, ["heck", "yeah!"]]},  
    ]          
    arrs.each do |arr|
      returned = JsonEtl::Transform::Utilities.deep_clean(arr["original"])
      assert_equal(arr["expected"], returned)
    end
  end

  def test_fetch_slice
    hash_original = {"blerg" => {"blorg" => {"whoops" => "oops", "blarg" => "bleg"}}}
    hash_result = JsonEtl::Transform::Utilities.fetch_slice("/", hash_original)
    assert_equal(hash_original, hash_result)
    hash_result = JsonEtl::Transform::Utilities.fetch_slice("blerg", hash_original)
    assert_equal({"blorg"=>{"whoops"=>"oops", "blarg"=>"bleg"}}, hash_result)    
    hash_original = {"blerg" => {"blorg" => {"whoops" => "oops", "blarg" => "bleg"}}}
    hash_result = JsonEtl::Transform::Utilities.fetch_slice("blerg/blorg/whoops", hash_original)
    assert_equal('oops', hash_result)    
  end

  def test_hash_from_path
    hash_result = JsonEtl::Transform::Utilities.field_hash_from_path('foo/bar/baz', "destfield", "bat")
    hash = {"foo"=>{"bar"=>{"baz"=>{"destfield"=>"bat"}}}}
    assert_equal(hash, hash_result)
  end
end