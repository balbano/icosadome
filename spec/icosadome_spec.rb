require 'minitest/spec'
require 'minitest/autorun'

require 'openstudio'
require_relative '../lib/icosadome'
require_relative '../lib/geodesic_dome_1V'

describe Icosadome do
  before do
    geometry = GeodesicDome1V.new(radius: 4)
    @model = Icosadome.new
    @model.make_icosadome(geometry)
    @building = @model.getBuilding
    @path_to_template = File.dirname(__FILE__) + '/../templates/MidriseApartment.osm'
  end

  describe 'spaces' do
    it 'has 1 space' do
      @model.getSpaces.length.must_equal 1
    end
    it 'has a thermal zone attched to each space' do
      @model.getSpaces.each do |space|
        space.thermalZone.empty?.must_equal false
      end
    end
  end

  describe 'thermal zones' do
    it 'can add thermostats' do
      @model.add_thermostats(heating_setpoint: 24, cooling_setpoint: 28)
      @model.getThermalZones.each do |zone|
        zone.thermostatSetpointDualSetpoint.empty?.must_equal false
      end
    end
    it 'can add hvac' do
      @model.add_hvac
      @model.getThermalZones.each do |zone|
        zone.equipment.length.wont_equal 0
      end
    end
  end
  
  it 'can add a default space type' do
    @model.add_default_space_type_from_template(@path_to_template)
    @building.spaceType.empty?.must_equal false
  end

  it 'can add a default construction set' do
    @building.defaultConstructionSet.empty?.must_equal false
  end
  
end
