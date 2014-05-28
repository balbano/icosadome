require 'openstudio'
require_relative 'lib/icosadome'
require_relative 'lib/geodesic_dome_1V'

geometry = GeodesicDome1V.new(radius: 4)
model = Icosadome.new
model.make_icosadome(geometry)
model.add_windows(0.8)
model.add_hvac
path_to_template = File.dirname(__FILE__) + '/templates/MidriseApartment.osm'
model.add_default_space_type_from_template(path_to_template)
model.add_default_construction_set_from_template(path_to_template)

puts 'Created new IcosaDome'
export_directory = "#{Dir.pwd}/runs"
export_name = Pathname.new("#{File.basename(__FILE__)}").sub_ext('.osm')
model.save_openstudio_osm(osm_save_directory: export_directory,
                             osm_name: export_name)
puts "Saved #{export_name} in #{export_directory}"
