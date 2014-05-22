require 'openstudio'
require_relative 'icosadome'
require 'minitest/spec'
require 'minitest/autorun'

describe IcosaDome do
  before do
    @dome = IcosaDome.new
    @dome.make_dome(1)
    @vertices = @dome.vertices_by_location
    @surfaces = @dome.surfaces_by_location
  end

  describe "converting spherical coords to cartesian coords" do
    it "knows up is up" do
      @dome.spherical_to_cartesian(1, Math::PI/2, 0).must_equal [0, 0, 1]
    end
    it "knows down is down" do
      @dome.spherical_to_cartesian(1, -Math::PI/2, 0).must_equal [0, 0, -1]
    end
    it "knows north is north" do
      @dome.spherical_to_cartesian(1, 0, 0).must_equal [0, 1, 0]
    end
    it "knows east is east" do
      @dome.spherical_to_cartesian(1, 0, Math::PI/2).must_equal [1, 0, 0]
    end
    it "knows south is south" do
      @dome.spherical_to_cartesian(1, 0, Math::PI).must_equal [0, -1, 0]
    end
    it "knows west is west" do
      @dome.spherical_to_cartesian(1, 0, 3*Math::PI/2).must_equal [-1, 0, 0]
    end
  end

  describe "vertices" do
    it "has a top point" do
      @vertices[:top].must_be_kind_of OpenStudio::Point3d
    end
    it "has an upper pentagon with 5 points" do
      @vertices[:upper_pentagon].length.must_equal 5
      @vertices[:upper_pentagon].each do |point|
        point.must_be_kind_of OpenStudio::Point3d
      end
    end
    it "has a lower pentagon with 5 points" do
      @vertices[:lower_pentagon].length.must_equal 5
      @vertices[:lower_pentagon].each do |point|
        point.must_be_kind_of OpenStudio::Point3d
      end
    end
    it "sits on the ground" do
      @vertices[:lower_pentagon].each do |point|
        point.z.must_equal 0
      end
    end
  end

  describe "surfaces" do
    it "has a roof with 5 'RoofCeiling' surfaces" do
      @surfaces[:roof].length.must_equal 5
      @surfaces[:roof].each do |surface|
        surface.surfaceType.must_equal 'RoofCeiling'
      end
    end
    it "has an upper wall with 5 'Wall' surfaces" do
      @surfaces[:upper_wall].length.must_equal 5
      @surfaces[:upper_wall].each do |surface|
        surface.surfaceType.must_equal 'Wall'
      end
    end
    it "has a lower wall with 5 'Wall' surfaces" do
      @surfaces[:lower_wall].length.must_equal 5
      @surfaces[:lower_wall].each do |surface|
        surface.surfaceType.must_equal 'Wall'
      end
    end
    it "has a floor with 1 'Floor' surface" do
      @surfaces[:floor].length.must_equal 1
      @surfaces[:floor].each do |surface|
        surface.surfaceType.must_equal 'Floor'
      end
    end
  end

  describe "spaces" do
    it "has 1 space" do
      @dome.getSpaces.length.must_equal 1
    end
    it "has a thermal zone attched to each space" do
      @dome.getSpaces.each do |space|
        space.thermalZone.empty?.must_equal false
      end
    end
  end

  describe "HVAC" do
    it "uses a packaged terminal heat pump" do
      @dome.getThermalZones.each do |zone|
        zone.zoneConditioningEquipmentListName.must_equal "ZoneHVACPackagedTerminalHeatPump"
      end
    end
  end

end
