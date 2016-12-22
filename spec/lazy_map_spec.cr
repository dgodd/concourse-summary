require "spec"
require "../src/concourse-summary/lazy_map"

describe "Array.lazy_map" do
  it "processes the elements" do
    [1,2].lazy_map { |x| x * 2 }.should eq [2,4]
  end
end
