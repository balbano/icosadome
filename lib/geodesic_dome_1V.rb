require 'openstudio'

class GeodesicDome1V
  attr_reader :radius, :vertices

  def initialize(radius: 4)
    @radius = radius
    add_vertices
    raise_to_ground_plane
  end

  def add_vertices
    # Formula: http://en.wikipedia.org/wiki/Icosahedron#Spherical_coordinates
    @vertices = []
    @vertices << OpenStudio::Point3d.new(0, 0, radius)

    upper_azimuths = (0..4).to_a.map { |i| i * 2 * Math::PI / 5 }
    lower_azimuths = (0..4).to_a.map { |i| Math::PI / 5 + i * 2 * Math::PI / 5 }

    upper_azimuths.each do |azimuth|
      @vertices << spherical_to_point3d(radius, Math.atan(0.5), azimuth)
    end

    lower_azimuths.each do |azimuth|
      @vertices << spherical_to_point3d(radius, -Math.atan(0.5), azimuth)
    end
  end

  def raise_to_ground_plane
    pentagon_point_z = spherical_to_cartesian(radius, Math.atan(0.5), 0)[2]
    z_offset = OpenStudio::Vector3d.new(0, 0, pentagon_point_z)
    @vertices.map! { |point| point + z_offset }
  end

  def spherical_to_point3d(radius, altitude, azimuth)
    point = spherical_to_cartesian(radius, altitude, azimuth)
    OpenStudio::Point3d.new(*point)
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

  def top
    vertices[0]
  end

  def upper_pentagon
    vertices[1..5]
  end

  def lower_pentagon
    vertices[6..10]
  end

  def vertices_by_face
    tops = [top] * 5 # Repeat the top point for zipping.
    # Counter-clockwise defines outward facing normal.
    tops.zip(upper_pentagon.rotate, upper_pentagon) +
      lower_pentagon.zip(upper_pentagon, upper_pentagon.rotate) +
      upper_pentagon.zip(lower_pentagon, lower_pentagon.rotate(-1)) +
      [lower_pentagon]
  end
end
