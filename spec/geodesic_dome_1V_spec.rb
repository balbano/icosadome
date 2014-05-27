require 'minitest/spec'
require 'minitest/autorun'

require 'openstudio'
require_relative '../lib/geodesic_dome_1V'

describe GeodesicDome1V do
  before do
    @dome = GeodesicDome1V.new(radius: 4)
  end

  describe 'converting spherical coords to cartesian coords' do
    it 'knows up is up' do
      @dome.spherical_to_cartesian(1, Math::PI / 2, 0).must_equal [0, 0, 1]
    end
    it 'knows down is down' do
      @dome.spherical_to_cartesian(1, -Math::PI / 2, 0).must_equal [0, 0, -1]
    end
    it 'knows north is north' do
      @dome.spherical_to_cartesian(1, 0, 0).must_equal [0, 1, 0]
    end
    it 'knows east is east' do
      @dome.spherical_to_cartesian(1, 0, Math::PI / 2).must_equal [1, 0, 0]
    end
    it 'knows south is south' do
      @dome.spherical_to_cartesian(1, 0, Math::PI).must_equal [0, -1, 0]
    end
    it 'knows west is west' do
      @dome.spherical_to_cartesian(1, 0, 3 * Math::PI / 2).must_equal [-1, 0, 0]
    end
  end

  describe 'vertices' do
    it 'has 11 vertices' do
      @dome.vertices.length.must_equal 11
    end
    it 'has vertices that are points' do
      @dome.vertices.each do |vertex|
        vertex.must_be_kind_of OpenStudio::Point3d
      end
    end
    it 'it has 1 top point' do
      @dome.top.must_be_kind_of OpenStudio::Point3d
    end
    it 'has an upper pentagon with 5 points' do
      @dome.upper_pentagon.length.must_equal 5
      @dome.upper_pentagon.each do |vertex|
        vertex.must_be_kind_of OpenStudio::Point3d
      end
    end
    it 'has a lower pentagon with 5 points' do
      @dome.lower_pentagon.length.must_equal 5
      @dome.lower_pentagon.each do |vertex|
        vertex.must_be_kind_of OpenStudio::Point3d
      end
    end
    it 'sits on the ground' do
      @dome.lower_pentagon.each do |vertex|
        vertex.z.must_equal 0
      end
    end
  end

  describe 'faces' do
    it 'has 16 faces' do
      @dome.vertices_by_face.length.must_equal 16
    end
  end

end
