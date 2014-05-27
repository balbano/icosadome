require 'openstudio'

# Make a dome! Make an instance of IcosaDome and call make_dome(radius).
class Building < OpenStudio::Model::Model
  attr_reader :geometry

  def make_building(geometry)
    @geometry = geometry
    faces = geometry.vertices_by_face
    surfaces = faces.map { |vertices| make_surface(vertices) }
    add_space(surfaces)
    match_all_surfaces
    add_thermal_zones
  end

  def make_surface(points)
    point_vector = OpenStudio::Point3dVector.new(points)
    OpenStudio::Model::Surface.new(point_vector, self)
  end

  def add_space(surfaces)
    space = OpenStudio::Model::Space.new(self)
    surfaces.each do |surface|
      surface.setSpace(space)
      surface.assignDefaultSurfaceType
    end
  end
  
  def match_all_surfaces
    spaces = OpenStudio::Model::SpaceVector.new(getSpaces)
    OpenStudio::Model.matchSurfaces(spaces) 
  end

  def add_windows(ratio)
    getSurfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == 'Outdoors'
      add_window(surface, ratio)
    end
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

  def save_openstudio_osm(params)
    osm_save_directory = params[:osm_save_directory]
    osm_name = params[:osm_name]
    save_path = OpenStudio::Path.new("#{osm_save_directory}/#{osm_name}")
    save(save_path, true)
  end
end
