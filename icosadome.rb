require 'openstudio'

class IcosaDome < OpenStudio::Model::Model
  attr_reader :radius, :vertices, :surfaces
  
  def make_dome(radius)
    @surface_types_by_face_type = {roof: "RoofCeiling", upper_wall: "Wall", 
                                   lower_wall: "Wall", floor: "Floor"}
    @radius = radius
    @vertices = make_vertices(@radius)
    @vertices = raise_to_ground_plane(@vertices, @radius)
    @vertices_by_face = make_vertices_by_face(@vertices)
    make_space(@vertices_by_face)
    add_thermal_zones()
    add_hvac()
    @surfaces[:upper_wall].each {|surface| add_window(surface, 0.8)}
  end

  def make_space(vertices_by_face)
    space = OpenStudio::Model::Space.new(self)
    @surfaces = {}
    vertices_by_face.each do |face_type, faces|
      @surfaces[face_type] = []
      faces.each do |face|
        p_vector = OpenStudio::Point3dVector.new(face)
        surface = OpenStudio::Model::Surface.new(p_vector, self)
        surface.setSpace(space)
        surface.setSurfaceType(@surface_types_by_face_type[face_type])
        @surfaces[face_type] << surface
      end
    end
  end
  
  def add_thermal_zones()
    self.getSpaces.each do |space|
      if space.thermalZone.empty?
        new_thermal_zone = OpenStudio::Model::ThermalZone.new(self)
        space.setThermalZone(new_thermal_zone)
      end
    end
  end

  def add_hvac()
    # System 2 is a packaged terminal heat pump.
    hvac = OpenStudio::Model::addSystemType2(self, self.getThermalZones)
  end

  def add_window(surface, ratio)
    ratio = 1 - ratio
    window_vertices = OpenStudio::Point3dVector.new
    surface.vertices.each do |vertex|
      x = vertex.x + (surface.centroid.x - vertex.x)*ratio
      y = vertex.y + (surface.centroid.y - vertex.y)*ratio
      z = vertex.z + (surface.centroid.z - vertex.z)*ratio
      window_vertices << OpenStudio::Point3d.new(x, y, z)
    end
    window = OpenStudio::Model::SubSurface.new(window_vertices, self)
    window.setSurface(surface)
  end

  def make_vertices_by_face(vertices)
    vertices_by_face = {}
    tops = [vertices[:top]]*5 # Repeat the top point for zipping.
    # Counter-clockwise defines outward facing normal.
    vertices_by_face[:roof] = tops.zip(vertices[:upper_pentagon].rotate, 
                                       vertices[:upper_pentagon])
    vertices_by_face[:lower_wall] = vertices[:upper_pentagon].zip(
                                      vertices[:lower_pentagon],
                                      vertices[:lower_pentagon].rotate(-1)
                                    )
    vertices_by_face[:upper_wall] = vertices[:lower_pentagon].zip(
                                      vertices[:upper_pentagon],
                                      vertices[:upper_pentagon].rotate
                                    )
    vertices_by_face[:floor] = [vertices[:lower_pentagon]] # Array must be 2d.
    vertices_by_face
  end

  def make_vertices(radius)
    # Generate all the vertices of an icosahedron except the bottom vertex.
    # Returns hash containing the top point and the upper and lower pentagons.
    # Formula: http://en.wikipedia.org/wiki/Icosahedron#Spherical_coordinates
    vertices = {}
    vertices[:top] = OpenStudio::Point3d.new(0, 0, radius)
    vertices[:upper_pentagon] = [] 
    vertices[:lower_pentagon] = []

    upper_azimuths = (0..4).to_a.map{|i| i*2*Math::PI/5}
    lower_azimuths = (0..4).to_a.map{|i| Math::PI/5 + i*2*Math::PI/5}
    
    upper_azimuths.each do |azi|
      point = spherical_to_cartesian(radius, Math.atan(0.5), azi)
      vertices[:upper_pentagon] << OpenStudio::Point3d.new(*point)
    end

    lower_azimuths.each do |azi|
      point = spherical_to_cartesian(radius, -Math.atan(0.5), azi)
      vertices[:lower_pentagon] << OpenStudio::Point3d.new(*point)
    end

    vertices
  end

  def raise_to_ground_plane(vertices, radius)
    pentagon_point_z = spherical_to_cartesian(radius, Math.atan(0.5), 0)[2]
    z_offset = OpenStudio::Vector3d.new(0, 0, pentagon_point_z)
    vertices[:top] += z_offset
    vertices[:upper_pentagon].map! {|point| point + z_offset}
    vertices[:lower_pentagon].map! {|point| point + z_offset}
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
    [x, y, z].map{|i| i.round(10)} 
  end
  
  def save_openstudio_osm(params)
    osm_save_directory = params[:osm_save_directory]
    osm_name = params[:osm_name]
    save_path = OpenStudio::Path.new("#{osm_save_directory}/#{osm_name}")
    self.save(save_path,true)
  end
end

if __FILE__ == $0
  dome = IcosaDome.new
  dome.make_dome(4)
  puts "Created new IcosaDome with radius #{dome.radius}"
  export_directory = "#{Dir.pwd}/runs"
  export_name = Pathname.new("#{File.basename(__FILE__)}").sub_ext('.osm')
  dome.save_openstudio_osm(osm_save_directory: export_directory,
                           osm_name: export_name) 
  puts "Saved #{export_name} in #{export_directory}"
end
