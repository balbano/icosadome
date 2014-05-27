require 'openstudio'
require_relative 'lib/building'
require_relative 'lib/geodesic_dome_1V'

dome = GeodesicDome1V.new(radius: 4)
building = Building.new
building.make_building(dome)
add_windows(0.8)

puts "Created new IcosaDome"
export_directory = "#{Dir.pwd}/runs"
export_name = Pathname.new("#{File.basename(__FILE__)}").sub_ext('.osm')
building.save_openstudio_osm(osm_save_directory: export_directory,
                          osm_name: export_name)
puts "Saved #{export_name} in #{export_directory}"
