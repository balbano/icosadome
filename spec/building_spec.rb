require 'minitest/spec'
require 'minitest/autorun'

require 'openstudio'
require_relative '../lib/building'
require_relative '../lib/geodesic_dome_1V'

describe Building do
  before do
    dome = GeodesicDome1V.new(radius: 4)
    @building = Building.new
    @building.make_building(dome)
  end

  describe 'spaces' do
    it 'has 1 space' do
      @building.getSpaces.length.must_equal 1
    end
    it 'has a thermal zone attched to each space' do
      @building.getSpaces.each do |space|
        space.thermalZone.empty?.must_equal false
      end
    end
  end

  describe 'thermal zones' do
    it 'can add thermostats' do
      @building.add_thermostats(heating_setpoint: 24, cooling_setpoint: 28)
      @building.getThermalZones.each do |zone|
        zone.thermostatSetpointDualSetpoint.empty?.must_equal false
      end
    end
    it 'can add hvac' do
      @building.add_hvac
      @building.getThermalZones.each do |zone|
        zone.equipment.length.wont_equal 0
      end
    end
  end

end
