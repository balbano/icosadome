require 'openstudio'

class IcosaDome < OpenStudio::Model::Model
  attr_reader :radius, :vertices, :surfaces_by_location

  def make_dome(radius)
    @surface_types_by_location = { roof: 'RoofCeiling', upper_wall: 'Wall',
                                   lower_wall: 'Wall', floor: 'Floor' }
    @radius = radius
    @vertices = make_vertices(@radius)
    @vertices = raise_to_ground_plane(@vertices, @radius)
    @vertices_by_face = make_vertices_by_face(@vertices)
    @surfaces_by_location = make_surfaces(@vertices_by_face)
    make_space(@surfaces_by_location)
    add_thermal_zones
    add_hvac
    @surfaces_by_location[:upper_wall].each { |surface| add_window(surface, 0.8) }
  end

  def make_space(surfaces_by_location)
    space = OpenStudio::Model::Space.new(self)
    surfaces_by_location.each do |location, surfaces|
      surfaces.each do |surface|
        surface.setSpace(space)
        surface.setSurfaceType(@surface_types_by_location[location])
      end
    end
  end

  def make_surfaces(vertices_by_face)
    @surfaces_by_location = {}
    vertices_by_face.each do |location, faces|
      @surfaces_by_location[location] = []
      faces.each do |face|
        surface = make_surface(face)
        @surfaces_by_location[location] << surface
      end
    end
    @surfaces_by_location
  end

  def make_surface(points)
    point_vector = OpenStudio::Point3dVector.new(points)
    OpenStudio::Model::Surface.new(point_vector, self)
  end

  def add_thermal_zones
    getSpaces.each do |space|
      next unless space.thermalZone.empty?
      new_thermal_zone = OpenStudio::Model::ThermalZone.new(self)
      space.setThermalZone(new_thermal_zone)
    end
  end

  def add_hvac
    # System 2 is a packaged terminal heat pump.
    OpenStudio::Model.addSystemType2(self, getThermalZones)
  end

  def add_window(surface, ratio)
    ratio = 1 - ratio
    window_vertices = OpenStudio::Point3dVector.new
    surface.vertices.each do |vertex|
      x = vertex.x + (surface.centroid.x - vertex.x) * ratio
      y = vertex.y + (surface.centroid.y - vertex.y) * ratio
      z = vertex.z + (surface.centroid.z - vertex.z) * ratio
      window_vertices << OpenStudio::Point3d.new(x, y, z)
    end
    window = OpenStudio::Model::SubSurface.new(window_vertices, self)
    window.setSurface(surface)
  end

  def make_vertices_by_face(vertices)
    tops = [vertices[:top]] * 5 # Repeat the top point for zipping.
    upper = vertices[:upper_pentagon]
    lower = vertices[:lower_pentagon]
    # Counter-clockwise defines outward facing normal.
    { roof: tops.zip(upper.rotate, upper),
      upper_wall: lower.zip(upper, upper.rotate),
      lower_wall: upper.zip(lower, lower.rotate(-1)),
      floor: [lower] }
  end

  def make_vertices(radius)
    # Generate all the vertices of an icosahedron except the bottom vertex.
    # Returns hash containing the top point and the upper and lower pentagons.
    # Formula: http://en.wikipedia.org/wiki/Icosahedron#Spherical_coordinates
    vertices = { top: OpenStudio::Point3d.new(0, 0, radius) }

    upper_azimuths = (0..4).to_a.map { |i| i * 2 * Math::PI / 5 }
    lower_azimuths = (0..4).to_a.map { |i| Math::PI / 5 + i * 2 * Math::PI / 5 }

    vertices[:upper_pentagon] = upper_azimuths.map do |azimuth|
      spherical_to_point3d(radius, Math.atan(0.5), azimuth)
    end

    vertices[:lower_pentagon] = lower_azimuths.map do |azimuth|
      spherical_to_point3d(radius, -Math.atan(0.5), azimuth)
    end

    vertices
  end

  def spherical_to_point3d(radius, altitude, azimuth)
    point = spherical_to_cartesian(radius, altitude, azimuth)
    OpenStudio::Point3d.new(*point)
  end

  def raise_to_ground_plane(vertices, radius)
    pentagon_point_z = spherical_to_cartesian(radius, Math.atan(0.5), 0)[2]
    z_offset = OpenStudio::Vector3d.new(0, 0, pentagon_point_z)
    vertices[:top] += z_offset
    vertices[:upper_pentagon].map! { |point| point + z_offset }
    vertices[:lower_pentagon].map! { |point| point + z_offset }
    vertices
  end

  def spherical_to_cartesian(radius, altitude, azimuth)
    # Altitude range: -PI/2 to PI/2
    # Azimuth range: 0 to 2PI
    # Rounds the result to 10 decimal places to make sure results that should
    # be zero are actually zero. Is there a better way to do this?
    x = radius * Math.cos(altitude) * Math.sin(azimuth)
    y = radius * Math.cos(altitude) * Math.cos(azimuth)
    z = radius * Math.sin(altitude)
    [x, y, z].map { |i| i.round(10) }
  end

  def save_openstudio_osm(params)
    osm_save_directory = params[:osm_save_directory]
    osm_name = params[:osm_name]
    save_path = OpenStudio::Path.new("#{osm_save_directory}/#{osm_name}")
    save(save_path, true)
  end
end

if __FILE__ == $PROGRAM_NAME
  dome = IcosaDome.new
  dome.make_dome(4)
  puts "Created new IcosaDome with radius #{dome.radius}"
  export_directory = "#{Dir.pwd}/runs"
  export_name = Pathname.new("#{File.basename(__FILE__)}").sub_ext('.osm')
  dome.save_openstudio_osm(osm_save_directory: export_directory,
                           osm_name: export_name)
  puts "Saved #{export_name} in #{export_directory}"
end
