# Grid Generator for SketchUp
# Creates various types of grids for surveying, planning, and layout work

require 'sketchup.rb'

module GridGenerator
  
  def self.create_coordinate_grid
    puts "=== COORDINATE GRID GENERATOR ==="
    
    # Get grid settings
    prompts = [
      "Grid Size X (width):",
      "Grid Size Y (height):", 
      "Grid Spacing:",
      "Grid Units:",
      "Show Labels?",
      "Label Every (intervals):",
      "Grid Line Style:",
      "Starting X Coordinate:",
      "Starting Y Coordinate:"
    ]
    
    defaults = ["1000", "1000", "100", "meters", "Yes", "5", "Thin", "0", "0"]
    list = ["", "", "", "meters|feet|inches", "Yes|No", "", "Thin|Normal|Thick", "", ""]
    
    result = UI.inputbox(prompts, defaults, list, "Coordinate Grid Settings")
    return unless result
    
    grid_x = result[0].to_f
    grid_y = result[1].to_f
    spacing = result[2].to_f
    units = result[3]
    show_labels = result[4] == "Yes"
    label_interval = result[5].to_i.clamp(1, 50)
    line_style = result[6]
    start_x = result[7].to_f
    start_y = result[8].to_f
    
    if grid_x <= 0 || grid_y <= 0 || spacing <= 0
      UI.messagebox("Grid dimensions and spacing must be greater than 0")
      return
    end
    
    create_grid(grid_x, grid_y, spacing, units, show_labels, label_interval, line_style, start_x, start_y)
  end
  
  def self.create_grid(width, height, spacing, units, show_labels, label_interval, line_style, start_x, start_y)
    puts "Creating #{width}×#{height} grid with #{spacing} #{units} spacing..."
    
    begin
      model = Sketchup.active_model
      entities = model.active_entities
      
      model.start_operation('Create Coordinate Grid', true)
      
      # Create main grid group
      grid_group = entities.add_group
      grid_group.name = "Coordinate Grid (#{spacing}#{units[0]})"
      grid_entities = grid_group.entities
      
      # Convert to SketchUp units (inches)
      scale_factor = case units
      when "meters"
        39.3701
      when "feet"
        12.0
      when "inches"
        1.0
      else
        39.3701
      end
      
      width_su = width * scale_factor
      height_su = height * scale_factor
      spacing_su = spacing * scale_factor
      start_x_su = start_x * scale_factor
      start_y_su = start_y * scale_factor
      
      # Calculate number of grid lines
      x_lines = (width / spacing).to_i + 1
      y_lines = (height / spacing).to_i + 1
      
      puts "Creating #{x_lines} vertical and #{y_lines} horizontal lines"
      
      # Create vertical grid lines (parallel to Y-axis)
      x_lines.times do |i|
        x_pos = start_x_su + i * spacing_su
        
        # Create line from bottom to top
        start_point = Geom::Point3d.new(x_pos, start_y_su, 0)
        end_point = Geom::Point3d.new(x_pos, start_y_su + height_su, 0)
        
        line = grid_entities.add_line(start_point, end_point)
        style_grid_line(line, line_style)
        
        # Add labels if requested
        if show_labels && i % label_interval == 0
          x_coord = start_x + i * spacing
          label_text = "#{x_coord.round(1)}"
          add_grid_label(grid_entities, x_pos, start_y_su - 50, label_text, units)
        end
      end
      
      # Create horizontal grid lines (parallel to X-axis)
      y_lines.times do |i|
        y_pos = start_y_su + i * spacing_su
        
        # Create line from left to right
        start_point = Geom::Point3d.new(start_x_su, y_pos, 0)
        end_point = Geom::Point3d.new(start_x_su + width_su, y_pos, 0)
        
        line = grid_entities.add_line(start_point, end_point)
        style_grid_line(line, line_style)
        
        # Add labels if requested
        if show_labels && i % label_interval == 0
          y_coord = start_y + i * spacing
          label_text = "#{y_coord.round(1)}"
          add_grid_label(grid_entities, start_x_su - 100, y_pos, label_text, units)
        end
      end
      
      # Add corner coordinates
      if show_labels
        add_corner_labels(grid_entities, start_x_su, start_y_su, width_su, height_su, start_x, start_y, width, height, units)
      end
      
      model.commit_operation
      
      success_msg = "Grid created successfully!\n\n"
      success_msg += "• Size: #{width} × #{height} #{units}\n"
      success_msg += "• Spacing: #{spacing} #{units}\n"
      success_msg += "• Grid lines: #{x_lines + y_lines} total\n"
      success_msg += "• Labels: #{show_labels ? 'Yes' : 'No'}"
      
      UI.messagebox(success_msg)
      model.active_view.zoom_extents
      
    rescue => e
      puts "ERROR creating grid: #{e.message}"
      model.abort_operation if model
      UI.messagebox("Error creating grid: #{e.message}")
    end
  end
    def self.style_grid_line(line, style)
    case style
    when "Thin"
      line.style = Sketchup::Edge::STYLE_THIN_LINES
    when "Normal"
      # Normal style - no special styling (default)
      # Don't set any style property for normal lines
    when "Thick"
      line.style = Sketchup::Edge::STYLE_THICK_LINES
    end
  end
  
  def self.add_grid_label(entities, x, y, text, units)
    begin
      # Create a small text entity (using 3D text)
      position = Geom::Point3d.new(x, y, 0)
      
      # Create small construction point as label marker
      entities.add_cpoint(position)
      
      # Add text using built-in text functionality
      # Note: SketchUp's 3D text requires the 3D Text tool, so we'll use construction points with attributes
      text_group = entities.add_group
      text_group.name = "Label_#{text}#{units[0]}"
      
      # Add a small line as text indicator
      text_end = Geom::Point3d.new(x + 20, y + 20, 0)
      text_line = text_group.entities.add_line(position, text_end)
      text_line.set_attribute("grid_label", "text", text)
      text_line.set_attribute("grid_label", "units", units)
      
    rescue => e
      puts "Could not create label: #{e.message}"
    end
  end
  
  def self.add_corner_labels(entities, start_x, start_y, width, height, orig_x, orig_y, orig_width, orig_height, units)
    corners = [
      { pos: [start_x, start_y], label: "#{orig_x},#{orig_y}" },
      { pos: [start_x + width, start_y], label: "#{orig_x + orig_width},#{orig_y}" },
      { pos: [start_x, start_y + height], label: "#{orig_x},#{orig_y + orig_height}" },
      { pos: [start_x + width, start_y + height], label: "#{orig_x + orig_width},#{orig_y + orig_height}" }
    ]
    
    corners.each do |corner|
      position = Geom::Point3d.new(corner[:pos][0], corner[:pos][1], 5)
      point = entities.add_cpoint(position)
      point.set_attribute("corner_label", "coordinates", corner[:label])
    end
  end
  
  def self.create_surveyor_grid
    puts "=== SURVEYOR GRID GENERATOR ==="
    
    # Preset surveyor grid settings
    prompts = [
      "Survey Grid Type:",
      "Station Interval:",
      "Number of Stations X:",
      "Number of Stations Y:",
      "Starting Station Number:",
      "Show Station Numbers?",
      "Show Elevation Points?"
    ]
    
    defaults = ["Standard", "100", "10", "10", "1000", "Yes", "Yes"]
    list = ["Standard|Fine|Coarse", "", "", "", "", "Yes|No", "Yes|No"]
    
    result = UI.inputbox(prompts, defaults, list, "Surveyor Grid Settings")
    return unless result
    
    grid_type = result[0]
    interval = result[1].to_f
    stations_x = result[2].to_i.clamp(2, 50)
    stations_y = result[3].to_i.clamp(2, 50)
    start_station = result[4].to_i
    show_numbers = result[5] == "Yes"
    show_elevations = result[6] == "Yes"
    
    # Adjust interval based on type
    case grid_type
    when "Fine"
      interval *= 0.5
    when "Coarse"
      interval *= 2.0
    end
    
    create_surveyor_grid_mesh(interval, stations_x, stations_y, start_station, show_numbers, show_elevations)
  end
  
  def self.create_surveyor_grid_mesh(interval, stations_x, stations_y, start_station, show_numbers, show_elevations)
    puts "Creating surveyor grid: #{stations_x}×#{stations_y} stations at #{interval}m intervals"
    
    begin
      model = Sketchup.active_model
      entities = model.active_entities
      
      model.start_operation('Create Surveyor Grid', true)
      
      # Create surveyor grid group
      survey_group = entities.add_group
      survey_group.name = "Survey Grid (#{interval}m)"
      
      # Create subgroups
      grid_lines_group = survey_group.entities.add_group
      grid_lines_group.name = "Grid Lines"
      
      stations_group = survey_group.entities.add_group
      stations_group.name = "Survey Stations"
      
      # Convert to SketchUp units
      interval_su = interval * 39.3701 * 0.1  # Scale down for visibility
      
      # Create grid lines
      create_survey_grid_lines(grid_lines_group.entities, stations_x, stations_y, interval_su)
      
      # Create survey stations
      create_survey_stations(stations_group.entities, stations_x, stations_y, interval_su, start_station, show_numbers, show_elevations)
      
      model.commit_operation
      
      total_stations = stations_x * stations_y
      UI.messagebox("Survey grid created!\n\n• #{stations_x}×#{stations_y} = #{total_stations} stations\n• Station interval: #{interval}m\n• Starting station: #{start_station}")
      
      model.active_view.zoom_extents
      
    rescue => e
      puts "ERROR creating surveyor grid: #{e.message}"
      model.abort_operation if model
      UI.messagebox("Error: #{e.message}")
    end
  end
  
  def self.create_survey_grid_lines(entities, stations_x, stations_y, interval)
    # Create vertical lines
    stations_x.times do |i|
      x_pos = i * interval
      start_point = Geom::Point3d.new(x_pos, 0, 0)
      end_point = Geom::Point3d.new(x_pos, (stations_y - 1) * interval, 0)
      
      line = entities.add_line(start_point, end_point)
      line.style = Sketchup::Edge::STYLE_THIN_LINES
    end
    
    # Create horizontal lines
    stations_y.times do |j|
      y_pos = j * interval
      start_point = Geom::Point3d.new(0, y_pos, 0)
      end_point = Geom::Point3d.new((stations_x - 1) * interval, y_pos, 0)
      
      line = entities.add_line(start_point, end_point)
      line.style = Sketchup::Edge::STYLE_THIN_LINES
    end
  end
  
  def self.create_survey_stations(entities, stations_x, stations_y, interval, start_station, show_numbers, show_elevations)
    station_number = start_station
    
    stations_y.times do |j|
      stations_x.times do |i|
        x_pos = i * interval
        y_pos = j * interval
        z_pos = show_elevations ? rand * 20 - 10 : 0  # Random elevation for demo
        
        position = Geom::Point3d.new(x_pos, y_pos, z_pos)
        
        # Create station point
        station_point = entities.add_cpoint(position)
        station_point.set_attribute("survey", "station_number", station_number)
        station_point.set_attribute("survey", "elevation", z_pos)
        
        # Add station marker (small circle)
        create_station_marker(entities, position, station_number, show_numbers)
        
        station_number += 1
      end
    end
    
    puts "Created #{stations_x * stations_y} survey stations"
  end
  
  def self.create_station_marker(entities, position, station_number, show_numbers)
    # Create a small circle to mark the station
    center = position
    normal = Geom::Vector3d.new(0, 0, 1)
    radius = 5  # Small radius for station marker
    
    begin
      # Create circle
      circle = entities.add_circle(center, normal, radius, 12)  # 12 segments for circle
      
      # Create the face
      circle_face = entities.add_face(circle)
      if circle_face
        circle_face.set_attribute("survey", "station", station_number)
      end
      
    rescue => e
      # Fallback: just use construction point
      puts "Could not create station marker, using point: #{e.message}"
    end
  end
  
  def self.create_property_boundary_grid
    puts "=== PROPERTY BOUNDARY GRID ==="
    
    prompts = [
      "Property Width (feet):",
      "Property Depth (feet):",
      "Setback Front (feet):",
      "Setback Rear (feet):",
      "Setback Left (feet):",
      "Setback Right (feet):",
      "Grid Spacing (feet):",
      "Show Building Envelope?"
    ]
    
    defaults = ["100", "150", "25", "20", "10", "10", "10", "Yes"]
    
    result = UI.inputbox(prompts, defaults, "Property Boundary Grid")
    return unless result
    
    width = result[0].to_f
    depth = result[1].to_f
    setback_front = result[2].to_f
    setback_rear = result[3].to_f
    setback_left = result[4].to_f
    setback_right = result[5].to_f
    spacing = result[6].to_f
    show_envelope = result[7] == "Yes"
    
    create_property_grid(width, depth, setback_front, setback_rear, setback_left, setback_right, spacing, show_envelope)
  end
  
  def self.create_property_grid(width, depth, sf, sr, sl, sr_right, spacing, show_envelope)
    puts "Creating property boundary grid..."
    
    begin
      model = Sketchup.active_model
      entities = model.active_entities
      
      model.start_operation('Property Boundary Grid', true)
      
      property_group = entities.add_group
      property_group.name = "Property Grid"
      
      # Convert to SketchUp units
      width_su = width * 12
      depth_su = depth * 12
      spacing_su = spacing * 12
      sf_su = sf * 12
      sr_su = sr * 12
      sl_su = sl * 12
      sr_right_su = sr_right * 12
      
      # Create property boundary
      boundary_points = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width_su, 0, 0),
        Geom::Point3d.new(width_su, depth_su, 0),
        Geom::Point3d.new(0, depth_su, 0)
      ]
      
      property_face = property_group.entities.add_face(boundary_points)
      if property_face
        property_face.set_attribute("property", "type", "boundary")
      end
      
      # Create grid within property
      x_lines = (width / spacing).to_i + 1
      y_lines = (depth / spacing).to_i + 1
      
      # Vertical grid lines
      x_lines.times do |i|
        x_pos = i * spacing_su
        next if x_pos > width_su
        
        line = property_group.entities.add_line(
          Geom::Point3d.new(x_pos, 0, 0),
          Geom::Point3d.new(x_pos, depth_su, 0)
        )
        line.style = Sketchup::Edge::STYLE_THIN_LINES
      end
      
      # Horizontal grid lines
      y_lines.times do |i|
        y_pos = i * spacing_su
        next if y_pos > depth_su
        
        line = property_group.entities.add_line(
          Geom::Point3d.new(0, y_pos, 0),
          Geom::Point3d.new(width_su, y_pos, 0)
        )
        line.style = Sketchup::Edge::STYLE_THIN_LINES
      end
      
      # Create building envelope if requested
      if show_envelope
        envelope_points = [
          Geom::Point3d.new(sl_su, sf_su, 1),
          Geom::Point3d.new(width_su - sr_right_su, sf_su, 1),
          Geom::Point3d.new(width_su - sr_right_su, depth_su - sr_su, 1),
          Geom::Point3d.new(sl_su, depth_su - sr_su, 1)
        ]
        
        envelope_face = property_group.entities.add_face(envelope_points)
        if envelope_face
          envelope_face.set_attribute("property", "type", "building_envelope")
          
          # Apply different material to building envelope
          materials = model.materials
          envelope_material = materials["Building_Envelope"] || materials.add("Building_Envelope")
          envelope_material.color = [200, 255, 200]
          envelope_material.alpha = 0.3
          envelope_face.material = envelope_material
        end
      end
      
      model.commit_operation
      
      buildable_width = width - sl - sr_right
      buildable_depth = depth - sf - sr
      buildable_area = buildable_width * buildable_depth
      
      UI.messagebox("Property grid created!\n\n• Property: #{width}' × #{depth}'\n• Building envelope: #{buildable_width.round(1)}' × #{buildable_depth.round(1)}'\n• Buildable area: #{buildable_area.round(0)} sq ft")
      
      model.active_view.zoom_extents
      
    rescue => e
      puts "ERROR creating property grid: #{e.message}"
      model.abort_operation if model
      UI.messagebox("Error: #{e.message}")
    end
  end
  
  def self.create_test_grids
    puts "=== CREATING TEST GRIDS ==="
    
    # Create a simple coordinate grid for testing
    create_grid(500, 300, 50, "meters", true, 2, "Normal", 0, 0)
    
    UI.messagebox("Test grid created! Check your model.")
  end

  def self.create_terrain_mesh_grid
    puts "=== ARCHICAD-COMPATIBLE TERRAIN MESH GRID GENERATOR ==="
    
    # Open file browser to select XYZ file
    file_path = UI.openpanel("Select XYZ File for Mesh Grid", "C:\\Users\\hmq\\Document", "XYZ Files|*.xyz|Text Files|*.txt|All Files|*.*||")
    
    unless file_path
      puts "No file selected"
      return
    end
    
    puts "Selected file: #{file_path}"
    
    # Verify file exists and is readable
    unless File.exist?(file_path) && File.readable?(file_path)
      UI.messagebox("Cannot read file: #{file_path}")
      return
    end
    
    puts "File exists and is readable (#{File.size(file_path)} bytes)"
    
    # Get terrain mesh grid settings with ArchiCAD compatibility
    prompts = [
      "Grid Spacing (meters):",
      "Simplification Factor (1-100):",
      "Grid Line Style:",
      "Show Elevation Labels?",
      "Create Terrain Faces?",
      "Preserve Original Coordinates?",
      "ArchiCAD Compatible Export?"
    ]
    
    defaults = ["50", "10", "Normal", "Yes", "Yes", "Yes", "Yes"]
    list = ["", "", "Thin|Normal|Thick", "Yes|No", "Yes|No", "Yes|No", "Yes|No"]
    
    result = UI.inputbox(prompts, defaults, list, "ArchiCAD-Compatible Terrain Grid Settings")
    return unless result
    
    grid_spacing = result[0].to_f
    simplification = result[1].to_i.clamp(1, 100)
    line_style = result[2]
    show_labels = result[3] == "Yes"
    create_faces = result[4] == "Yes"
    preserve_coords = result[5] == "Yes"
    archicad_compatible = result[6] == "Yes"
    
    if grid_spacing <= 0
      UI.messagebox("Grid spacing must be greater than 0")
      return
    end
    
    puts "Settings: Spacing=#{grid_spacing}m, Simplification=#{simplification}"
    puts "ArchiCAD Compatible: #{archicad_compatible}, Preserve Coordinates: #{preserve_coords}"
    
    generate_archicad_terrain_grid(file_path, grid_spacing, simplification, line_style, show_labels, create_faces, preserve_coords, archicad_compatible)
  end
  
  def self.generate_archicad_terrain_grid(file_path, grid_spacing, simplification, line_style, show_labels, create_faces, preserve_coords, archicad_compatible)
    puts "=== GENERATING ARCHICAD-COMPATIBLE TERRAIN GRID ==="
    
    begin
      # Read and process XYZ points preserving original coordinates
      points = read_xyz_preserve_coordinates(file_path, simplification, preserve_coords, archicad_compatible)
      
      if points.empty?
        UI.messagebox("No valid coordinate data found in file")
        return false
      end
      
      puts "Loaded #{points.length} valid terrain points with preserved coordinates"
      
      # Create SketchUp geometry
      model = Sketchup.active_model
      entities = model.active_entities
      
      model.start_operation('ArchiCAD Terrain Grid Generation', true)
      
      # Create main terrain grid group
      terrain_grid_group = entities.add_group
      terrain_grid_group.name = "ArchiCAD_Terrain_Grid_#{grid_spacing}m"
      
      # Add attributes for ArchiCAD compatibility
      terrain_grid_group.set_attribute("archicad", "coordinate_system", "preserved")
      terrain_grid_group.set_attribute("archicad", "grid_spacing", grid_spacing)
      terrain_grid_group.set_attribute("archicad", "source_file", File.basename(file_path))
      
      # Create subgroups for organization
      grid_lines_group = terrain_grid_group.entities.add_group
      grid_lines_group.name = "Grid_Lines"
      
      coordinate_points_group = terrain_grid_group.entities.add_group
      coordinate_points_group.name = "XYZ_Points"
      
      mesh_faces_group = nil
      if create_faces
        mesh_faces_group = terrain_grid_group.entities.add_group
        mesh_faces_group.name = "Terrain_Mesh"
      end
      
      labels_group = nil
      if show_labels
        labels_group = terrain_grid_group.entities.add_group
        labels_group.name = "Elevation_Labels"
      end
      
      # Create coordinate reference points for all XYZ data
      coord_points_created = create_coordinate_reference_points(coordinate_points_group.entities, points)
      puts "Created #{coord_points_created} coordinate reference points"
      
      # Generate the terrain-based mesh grid with preserved coordinates
      grid_result = create_archicad_terrain_grid(grid_lines_group.entities, points, grid_spacing, line_style, preserve_coords)
      
      if grid_result[:success]
        puts "Created #{grid_result[:grid_lines]} grid lines with preserved coordinates"
        
        # Create terrain faces if requested
        if create_faces && mesh_faces_group
          faces_created = create_archicad_terrain_faces(mesh_faces_group.entities, grid_result[:grid_points], points)
          puts "Created #{faces_created} terrain faces"
        end
        
        # Add coordinate labels if requested
        if show_labels && labels_group
          labels_created = add_archicad_coordinate_labels(labels_group.entities, grid_result[:grid_points], points)
          puts "Created #{labels_created} coordinate labels"
        end
        
        # Export coordinate data for ArchiCAD
        if archicad_compatible
          export_archicad_coordinates(terrain_grid_group, points, grid_result[:grid_points], file_path)
        end
        
        model.commit_operation
        
        success_msg = "ArchiCAD-compatible terrain grid created!\n\n"
        success_msg += "• #{grid_result[:grid_lines]} terrain-following grid lines\n"
        success_msg += "• Grid spacing: #{grid_spacing}m\n"
        success_msg += "• #{points.length} source terrain points\n"
        success_msg += "• #{coord_points_created} coordinate reference points\n"
        success_msg += "• #{faces_created || 0} terrain faces\n" if create_faces
        success_msg += "• #{labels_created || 0} coordinate labels\n" if show_labels
        success_msg += "• Original coordinates preserved for ArchiCAD\n" if preserve_coords
        
        UI.messagebox(success_msg)
        
        # Zoom to show the terrain grid
        model.active_view.zoom_extents
        
        return true
      else
        model.abort_operation
        UI.messagebox("Failed to create ArchiCAD terrain grid")
        return false
      end
        
    rescue => e
      puts "ERROR in ArchiCAD terrain grid generation: #{e.message}"
      puts "Error class: #{e.class}"
      puts "Backtrace: #{e.backtrace.join('\n')}"
      model.abort_operation if model
      UI.messagebox("Error generating ArchiCAD terrain grid: #{e.message}")
      return false
    end
  end

  
  def self.read_xyz_preserve_coordinates(file_path, simplification, preserve_coords, archicad_compatible)
    points = []
    valid_lines = 0
    
    puts "Reading XYZ file with coordinate preservation for ArchiCAD compatibility..."
    puts "Preserve coordinates: #{preserve_coords}, ArchiCAD compatible: #{archicad_compatible}"
    
    File.open(file_path, 'r') do |file|
      file.each_line.with_index do |line, index|
        next if line.strip.empty?
        
        # Skip lines based on simplification factor
        next if index % simplification != 0
        
        values = line.strip.split
        if values.length >= 3
          begin
            # Read original coordinates
            original_x = values[0].to_f
            original_y = values[1].to_f
            original_z = values[2].to_f
            
            if preserve_coords && archicad_compatible
              # For ArchiCAD compatibility, preserve original metric coordinates
              # Convert only for SketchUp display (minimal scaling to keep precision)
              display_scale = 1.0  # No scaling - use original coordinates
              
              # Convert to SketchUp units but preserve coordinate system
              x_su = original_x * 39.3701  # Convert meters to inches for SketchUp
              y_su = original_y * 39.3701
              z_su = original_z * 39.3701
              
            else
              # Legacy scaling method
              scale_factor = 0.1
              x_su = original_x * 39.3701 * scale_factor
              y_su = original_y * 39.3701 * scale_factor
              z_su = original_z * 39.3701 * scale_factor
            end
            
            points << {
              # SketchUp display coordinates
              x: x_su,
              y: y_su,
              z: z_su,
              # Original coordinates for ArchiCAD export
              original_x: original_x,
              original_y: original_y,
              original_z: original_z,
              # Coordinate data
              elevation: original_z,
              point3d: Geom::Point3d.new(x_su, y_su, z_su)
            }
            
            valid_lines += 1
            
          rescue => e
            puts "Skipping invalid line #{index + 1}: #{e.message}"
          end
        end
        
        # Progress update
        if index % 10000 == 0 && index > 0
          puts "Processed #{index} lines, found #{valid_lines} valid coordinate points"
        end
      end
    end
    
    if points.length > 0
      # Calculate coordinate bounds for info
      min_x = points.min_by { |p| p[:original_x] }[:original_x]
      max_x = points.max_by { |p| p[:original_x] }[:original_x]
      min_y = points.min_by { |p| p[:original_y] }[:original_y]
      max_y = points.max_by { |p| p[:original_y] }[:original_y]
      min_z = points.min_by { |p| p[:original_z] }[:original_z]
      max_z = points.max_by { |p| p[:original_z] }[:original_z]
      
      puts "Original coordinate bounds preserved:"
      puts "  X: #{min_x} to #{max_x} (range: #{(max_x - min_x).round(2)}m)"
      puts "  Y: #{min_y} to #{max_y} (range: #{(max_y - min_y).round(2)}m)"
      puts "  Z: #{min_z} to #{max_z} (range: #{(max_z - min_z).round(2)}m)"
    end
    
    puts "Successfully loaded #{points.length} terrain points with preserved coordinates"
    points
  end
  
  def self.create_coordinate_reference_points(entities, points)
    puts "Creating coordinate reference points for ArchiCAD compatibility..."
    
    points_created = 0
    
    points.each_with_index do |point, index|
      begin
        # Create construction point at original coordinate
        cpoint = entities.add_cpoint(point[:point3d])
        
        # Add coordinate attributes for ArchiCAD export
        cpoint.set_attribute("coordinate", "original_x", point[:original_x])
        cpoint.set_attribute("coordinate", "original_y", point[:original_y])
        cpoint.set_attribute("coordinate", "original_z", point[:original_z])
        cpoint.set_attribute("coordinate", "elevation", point[:elevation])
        cpoint.set_attribute("coordinate", "point_id", index + 1)
        
        points_created += 1
        
        # Progress update for large datasets
        if points_created % 5000 == 0
          puts "Created #{points_created} reference points..."
        end
        
      rescue => e
        puts "Error creating reference point #{index}: #{e.message}"
      end
    end
    
    puts "Created #{points_created} coordinate reference points"
    points_created
  end
  
  def self.create_archicad_terrain_grid(entities, points, grid_spacing, line_style, preserve_coords)
    puts "Creating ArchiCAD-compatible terrain grid with preserved coordinates..."
    
    # Find terrain bounds from original coordinates
    min_x = points.min_by { |p| p[:original_x] }[:original_x]
    max_x = points.max_by { |p| p[:original_x] }[:original_x]
    min_y = points.min_by { |p| p[:original_y] }[:original_y]
    max_y = points.max_by { |p| p[:original_y] }[:original_y]
    min_z = points.min_by { |p| p[:original_z] }[:original_z]
    max_z = points.max_by { |p| p[:original_z] }[:original_z]
    
    puts "Grid bounds (original coordinates):"
    puts "  X: #{min_x} to #{max_x} (#{(max_x - min_x).round(2)}m)"
    puts "  Y: #{min_y} to #{max_y} (#{(max_y - min_y).round(2)}m)"
    puts "  Z: #{min_z} to #{max_z} (#{(max_z - min_z).round(2)}m)"
    
    # Calculate grid dimensions using original coordinates
    grid_width = max_x - min_x
    grid_height = max_y - min_y
    
    # Number of grid lines
    x_lines = (grid_width / grid_spacing).to_i + 1
    y_lines = (grid_height / grid_spacing).to_i + 1
    
    puts "Creating #{x_lines} x #{y_lines} terrain-following grid"
    
    # Create grid points array with original coordinates
    grid_points = Array.new(x_lines) { Array.new(y_lines) }
    
    grid_lines_created = 0
    
    # Create vertical grid lines (following terrain elevation)
    x_lines.times do |i|
      x_coord = min_x + i * grid_spacing  # Original coordinate
      line_points = []
      
      y_lines.times do |j|
        y_coord = min_y + j * grid_spacing  # Original coordinate
        
        # Interpolate elevation at this grid point using nearby terrain data
        interpolated_z = interpolate_terrain_elevation_precise(points, x_coord, y_coord)
        
        # Convert to SketchUp display units
        x_su = x_coord * 39.3701
        y_su = y_coord * 39.3701
        z_su = interpolated_z * 39.3701
        
        grid_point = Geom::Point3d.new(x_su, y_su, z_su)
        
        grid_points[i][j] = {
          point3d: grid_point,
          original_x: x_coord,
          original_y: y_coord,
          original_z: interpolated_z,
          elevation: interpolated_z
        }
        
        line_points << grid_point
      end
      
      # Create vertical line following terrain
      if line_points.length >= 2
        (0...line_points.length - 1).each do |k|
          line = entities.add_line(line_points[k], line_points[k + 1])
          style_terrain_grid_line(line, line_style)
          
          # Add coordinate attributes to line
          line.set_attribute("grid", "type", "vertical")
          line.set_attribute("grid", "original_x", min_x + i * grid_spacing)
          line.set_attribute("grid", "spacing", grid_spacing)
          
          grid_lines_created += 1
        end
      end
    end
    
    # Create horizontal grid lines (following terrain elevation)
    y_lines.times do |j|
      line_points = []
      
      x_lines.times do |i|
        line_points << grid_points[i][j][:point3d] if grid_points[i][j]
      end
      
      # Create horizontal line following terrain
      if line_points.length >= 2
        (0...line_points.length - 1).each do |k|
          line = entities.add_line(line_points[k], line_points[k + 1])
          style_terrain_grid_line(line, line_style)
          
          # Add coordinate attributes to line
          line.set_attribute("grid", "type", "horizontal")
          line.set_attribute("grid", "original_y", min_y + j * grid_spacing)
          line.set_attribute("grid", "spacing", grid_spacing)
          
          grid_lines_created += 1
        end
      end
    end
    
    puts "Created #{grid_lines_created} terrain-following grid lines with preserved coordinates"
    
    {
      success: grid_lines_created > 0,
      grid_lines: grid_lines_created,
      grid_points: grid_points,
      x_lines: x_lines,
      y_lines: y_lines,
      bounds: {
        min_x: min_x, max_x: max_x,
        min_y: min_y, max_y: max_y,
        min_z: min_z, max_z: max_z
      }
    }
  end
  
  def self.interpolate_terrain_elevation_precise(points, target_x, target_y)
    # More precise interpolation using original coordinates
    search_radius = 500  # 500 meter search radius
    nearby_points = []
    
    # Find nearby points within search radius using original coordinates
    points.each do |point|
      distance = Math.sqrt((point[:original_x] - target_x)**2 + (point[:original_y] - target_y)**2)
      if distance <= search_radius
        nearby_points << { point: point, distance: distance }
      end
    end
    
    # If no points within radius, find closest point
    if nearby_points.empty?
      closest = points.min_by do |point|
        Math.sqrt((point[:original_x] - target_x)**2 + (point[:original_y] - target_y)**2)
      end
      return closest[:original_z]
    end
    
    # If only one point, use it
    if nearby_points.length == 1
      return nearby_points.first[:point][:original_z]
    end
    
    # Sort by distance and use closest points for interpolation
    nearby_points.sort_by! { |np| np[:distance] }
    
    # Use inverse distance weighting
    total_weight = 0
    weighted_sum = 0
    
    # Use up to 6 closest points for interpolation
    nearby_points.first([6, nearby_points.length].min).each do |np|
      if np[:distance] < 0.01  # Very close point
        return np[:point][:original_z]
      end
      
      weight = 1.0 / (np[:distance]**2)
      weighted_sum += np[:point][:original_z] * weight
      total_weight += weight
    end
    
    weighted_sum / total_weight
  end
  
  def self.create_archicad_terrain_faces(entities, grid_points, original_points)
    puts "Creating ArchiCAD-compatible terrain faces..."
    
    faces_created = 0
    x_size = grid_points.length
    y_size = x_size > 0 ? grid_points[0].length : 0
    
    return 0 unless x_size > 1 && y_size > 1
    
    # Create triangular faces from grid points
    (0...x_size - 1).each do |i|
      (0...y_size - 1).each do |j|
        # Get four corner points of grid cell
        p1 = grid_points[i][j]
        p2 = grid_points[i + 1][j]
        p3 = grid_points[i + 1][j + 1]
        p4 = grid_points[i][j + 1]
        
        if p1 && p2 && p3 && p4
          begin
            # Create two triangular faces for each grid cell
            # Triangle 1: p1, p2, p3
            face1 = entities.add_face(p1[:point3d], p2[:point3d], p3[:point3d])
            if face1
              face1.set_attribute("terrain", "type", "grid_face")
              face1.set_attribute("terrain", "grid_cell", "#{i}_#{j}_1")
              face1.set_attribute("archicad", "original_coords", "#{p1[:original_x]},#{p1[:original_y]},#{p1[:original_z]}")
              faces_created += 1
            end
            
            # Triangle 2: p1, p3, p4
            face2 = entities.add_face(p1[:point3d], p3[:point3d], p4[:point3d])
            if face2
              face2.set_attribute("terrain", "type", "grid_face")
              face2.set_attribute("terrain", "grid_cell", "#{i}_#{j}_2")
              face2.set_attribute("archicad", "original_coords", "#{p1[:original_x]},#{p1[:original_y]},#{p1[:original_z]}")
              faces_created += 1
            end
            
          rescue => e
            puts "Error creating face at grid cell #{i},#{j}: #{e.message}"
          end
        end
      end
    end
    
    puts "Created #{faces_created} terrain faces"
    faces_created
  end
  
  def self.add_archicad_coordinate_labels(entities, grid_points, original_points)
    puts "Adding ArchiCAD coordinate labels..."
    
    labels_created = 0
    x_size = grid_points.length
    y_size = x_size > 0 ? grid_points[0].length : 0
    
    return 0 unless x_size > 0 && y_size > 0
    
    # Add labels every few grid points to avoid clutter
    label_interval = [[(x_size / 10).to_i, 1].max, 5].min
    
    (0...x_size).step(label_interval) do |i|
      (0...y_size).step(label_interval) do |j|
        grid_point = grid_points[i][j]
        next unless grid_point
        
        begin
          # Create label with original coordinates
          position = grid_point[:point3d]
          
          # Create construction point with coordinate info
          label_point = entities.add_cpoint(position)
          
          # Format coordinate text
          coord_text = "#{grid_point[:original_x].round(2)},#{grid_point[:original_y].round(2)},#{grid_point[:original_z].round(2)}"
          
          # Add coordinate attributes
          label_point.set_attribute("label", "coordinates", coord_text)
          label_point.set_attribute("label", "original_x", grid_point[:original_x])
          label_point.set_attribute("label", "original_y", grid_point[:original_y])
          label_point.set_attribute("label", "original_z", grid_point[:original_z])
          label_point.set_attribute("archicad", "coordinate_label", true)
          
          labels_created += 1
          
        rescue => e
          puts "Error creating label at grid point #{i},#{j}: #{e.message}"
        end
      end
    end
    
    puts "Created #{labels_created} coordinate labels"
    labels_created
  end
  
  def self.export_archicad_coordinates(terrain_group, original_points, grid_points, source_file)
    puts "Exporting coordinate data for ArchiCAD compatibility..."
    
    begin
      # Create export directory
      export_dir = File.dirname(source_file)
      export_basename = File.basename(source_file, ".*")
      
      # Export original points with grid references
      original_export_file = File.join(export_dir, "#{export_basename}_original_coords.txt")
      
      File.open(original_export_file, 'w') do |file|
        file.puts "# Original XYZ coordinates for ArchiCAD import"
        file.puts "# Format: X Y Z (meters)"
        file.puts "# Source: #{File.basename(source_file)}"
        file.puts "# Generated: #{Time.now}"
        file.puts ""
        
        original_points.each_with_index do |point, index|
          file.puts "#{point[:original_x]} #{point[:original_y]} #{point[:original_z]}"
        end
      end
      
      # Export grid points
      if grid_points && grid_points.length > 0
        grid_export_file = File.join(export_dir, "#{export_basename}_grid_coords.txt")
        
        File.open(grid_export_file, 'w') do |file|
          file.puts "# Grid coordinates for ArchiCAD import"
          file.puts "# Format: X Y Z (meters)"
          file.puts "# Grid based on original terrain data"
          file.puts "# Generated: #{Time.now}"
          file.puts ""
          
          grid_points.each_with_index do |row, i|
            row.each_with_index do |grid_point, j|
              next unless grid_point
              file.puts "#{grid_point[:original_x]} #{grid_point[:original_y]} #{grid_point[:original_z]}"
            end
          end
        end
      end
      
      # Add export info to terrain group
      terrain_group.set_attribute("archicad", "export_original", original_export_file)
      terrain_group.set_attribute("archicad", "export_grid", grid_export_file) if grid_points
      terrain_group.set_attribute("archicad", "export_date", Time.now.to_s)
      
      puts "Exported coordinate data:"
      puts "  Original points: #{original_export_file}"
      puts "  Grid points: #{grid_export_file}" if grid_points
      
    rescue => e
      puts "Error exporting coordinate data: #{e.message}"
    end
  end
  
  def self.style_terrain_grid_line(line, style)
    case style
    when "Thin"
      line.style = Sketchup::Edge::STYLE_THIN_LINES
    when "Normal"
      # Normal style - no special styling (default)
    when "Thick"
      line.style = Sketchup::Edge::STYLE_THICK_LINES
    end
  end
  
  def self.create_terrain_grid_faces(entities, grid_points)
    faces_created = 0
    x_size = grid_points.length
    y_size = x_size > 0 ? grid_points[0].length : 0
    
    return 0 unless x_size > 1 && y_size > 1
    
    # Create faces from grid points
    (0...x_size - 1).each do |i|
      (0...y_size - 1).each do |j|
        p1 = grid_points[i][j]
        p2 = grid_points[i + 1][j]
        p3 = grid_points[i + 1][j + 1]
        p4 = grid_points[i][j + 1]
        
        if p1 && p2 && p3 && p4
          begin
            face = entities.add_face(p1[:point3d], p2[:point3d], p3[:point3d], p4[:point3d])
            faces_created += 1 if face
          rescue => e
            # Skip invalid faces
          end
        end
      end
    end
    
    faces_created
  end
  
  def self.smooth_terrain_grid_edges(entities)
    # Smooth edges by hiding them
    entities.each do |entity|
      if entity.is_a?(Sketchup::Edge)
        entity.soft = true
        entity.smooth = true
      end
    end
  end
  
  def self.add_terrain_elevation_labels(entities, grid_points, grid_spacing)
    labels_created = 0
    x_size = grid_points.length
    y_size = x_size > 0 ? grid_points[0].length : 0
    
    return 0 unless x_size > 0 && y_size > 0
    
    # Add labels at regular intervals
    interval = [x_size / 5, 1].max
    
    (0...x_size).step(interval) do |i|
      (0...y_size).step(interval) do |j|
        grid_point = grid_points[i][j]
        next unless grid_point
        
        begin
          label_point = entities.add_cpoint(grid_point[:point3d])
          label_point.set_attribute("elevation", "value", grid_point[:elevation])
          labels_created += 1
        rescue => e
          # Skip invalid labels
        end
      end
    end
    
    labels_created
  end

  def self.create_xyz_based_surveyor_grid
    puts "=== XYZ-BASED SURVEYOR GRID ==="
    
    file_path = UI.openpanel("Select XYZ File for Survey Grid", "C:\\Users\\hmq\\Downloads", "XYZ Files|*.xyz|Text Files|*.txt|All Files|*.*||")
    return unless file_path && File.exist?(file_path) && File.readable?(file_path)
    
    prompts = ["Station Interval (meters):", "Show Elevations?", "Station Prefix:"]
    defaults = ["100", "Yes", "STA"]
    result = UI.inputbox(prompts, defaults, "XYZ Survey Grid Settings")
    return unless result
    
    interval = result[0].to_f
    show_elevations = result[1] == "Yes"
    prefix = result[2]
    
    points = read_xyz_preserve_coordinates(file_path, 1, true, true)
    create_xyz_survey_grid(points, interval, show_elevations, prefix)
  end
  
  def self.create_xyz_survey_grid(points, interval, show_elevations, prefix)
    puts "Creating XYZ-based survey grid..."
    
    begin
      model = Sketchup.active_model
      entities = model.active_entities
      
      model.start_operation('XYZ Survey Grid', true)
      
      survey_group = entities.add_group
      survey_group.name = "XYZ Survey Grid"
      
      station_number = 1000
      
      points.each_with_index do |point, index|
        next if index % interval.to_i != 0  # Sample points
        
        create_xyz_station_marker(survey_group.entities, point[:point3d], "#{prefix}#{station_number}")
        station_number += 10
      end
      
      model.commit_operation
      UI.messagebox("XYZ survey grid created with #{station_number - 1000} stations")
      
    rescue => e
      model.abort_operation if model
      UI.messagebox("Error: #{e.message}")
    end
  end
  
  def self.create_xyz_station_marker(entities, position, station_name)
    # Create station marker
    marker = entities.add_cpoint(position)
    marker.set_attribute("survey", "station", station_name)
    
    # Add small circle
    begin
      circle = entities.add_circle(position, Geom::Vector3d.new(0, 0, 1), 5, 8)
      face = entities.add_face(circle) if circle
      face.set_attribute("survey", "station", station_name) if face
    rescue
      # Fallback to just construction point
    end
  end
  

  # Scanning the coordinates grid higher or lower settings
  def self.find_min_max_coordinates(data_xyz = nil)
    puts "Finding min/max coordinates from data..."

    file_path = UI.openpanel("Select XYZ File for Scanning", "C:\\Users\\hmq\\Documents", "XYZ Files|*.xyz|Text Files|*.txt|All Files|*.*||")

    unless file_path
      puts "No file selected"
      return
    end

    puts "Selected file: #{file_path}"

    unless File.exist?(file_path) && File.readable?(file_path)
      UI.messagebox("File does not exist or is not readable: #{file_path}")
      return
    end

    data_xyz = []

    begin
      File.foreach(file_path) do |line|
        parts = line.strip.split(/\s+/)
        if parts.length == 3
          x = parts[0].to_f
          y = parts[1].to_f
          z = parts[2].to_f
          data_xyz << { x: x, y: y, z: z }
        end
      end
    rescue => e
      puts "Error reading file: #{e.message}"
      return nil
    end 

    # Handle empty file after reading
    if data_xyz.empty?
      puts "No valid XYZ data found in the file."
      return nil
    end

    puts "Readding #{data_xyz.length} valid points from file."

    min_x = data_xyz[0][:x]
    max_x = data_xyz[0][:x]
    min_y = data_xyz[0][:y]
    max_y = data_xyz[0][:y]
    min_z = data_xyz[0][:z]
    max_z = data_xyz[0][:z]

    data_xyz.each do |point|
      min_x = [min_x, point[:x]].min
      min_y = [min_y, point[:y]].min
      min_z = [min_z, point[:z]].min

      max_x = [max_x, point[:x]].max
      max_y = [max_y, point[:y]].max
      max_z = [max_z, point[:z]].max
    end

    puts "\nInitial Min/Max Coordinates:"
    puts " X: #{min_x} - #{max_x}"
    puts " Y: #{min_y} - #{max_y}"
    puts " Z: #{min_z} - #{max_z}"

    # --- Elimination/Filtering Logic --- #
    min_allowed_z = 5.0
    max_allowed_z = 100.0

    puts "\nFiltering coordinates with Z between #{min_allowed_z} and #{max_allowed_z}..."
    filtered_data_xyz = data_xyz.select do |point|
      point[:z] >= min_allowed_z && point[:z] <= max_allowed_z
    end

    puts "Total original points: #{data_xyz.length}"
    puts "Total filtered points: #{filtered_data_xyz.length}"

    # finding min/max after filtering
    if filtered_data_xyz.empty?
      puts "No points remain after filtering."
      return nil
    end

    puts "Loaded #{filtered_data_xyz.length} points after filtering."

    filtered_min_x = filtered_data_xyz[0][:x]
    filtered_max_x = filtered_data_xyz[0][:x]
    filtered_min_y = filtered_data_xyz[0][:y]
    filtered_max_y = filtered_data_xyz[0][:y]
    filtered_min_z = filtered_data_xyz[0][:z]
    filtered_max_z = filtered_data_xyz[0][:z]

    filtered_data_xyz.each do |point|
      filtered_min_x = [filtered_min_x, point[:x]].min
      filtered_min_y = [filtered_min_y, point[:y]].min
      filtered_min_z = [filtered_min_z, point[:z]].min

      filtered_max_x = [filtered_max_x, point[:x]].max
      filtered_max_y = [filtered_max_y, point[:y]].max
      filtered_max_z = [filtered_max_z, point[:z]].max
    end

    puts "\nFiltered Min/Max Coordinates:"
    puts " X: #{filtered_min_x} - #{filtered_max_x}"
    puts " Y: #{filtered_min_y} - #{filtered_max_y}"
    puts " Z: #{filtered_min_z} - #{filtered_max_z}"

    # Return the filtered data
    {
      original_bounds: {
        min: { x: min_x, y: min_y, z: min_z },
        max: { x: max_x, y: max_y, z: max_z }
      },
      filtered_bounds: {
        min: { x: filtered_min_x, y: filtered_min_y, z: filtered_min_z },
        max: { x: filtered_max_x, y: filtered_max_y, z: filtered_max_z }
      },
      filtered_points: filtered_data_xyz
    }
  end
end


# Add menu items
unless file_loaded?(__FILE__)
  plugins_menu = UI.menu("Plugins")
  grid_menu = plugins_menu.add_submenu("Grid Generator")
  
  # Basic grid generators
  grid_menu.add_item("Coordinate Grid") { GridGenerator.create_coordinate_grid }
  grid_menu.add_item("Surveyor Grid") { GridGenerator.create_surveyor_grid }
  grid_menu.add_item("Property Boundary Grid") { GridGenerator.create_property_boundary_grid }
  
  grid_menu.add_separator
  
  # ArchiCAD-compatible terrain grid generators
  archicad_submenu = grid_menu.add_submenu("ArchiCAD Compatible Grids")
  archicad_submenu.add_item("Terrain Mesh Grid") { GridGenerator.create_terrain_mesh_grid }
  archicad_submenu.add_item("XYZ Survey Grid") { GridGenerator.create_xyz_based_surveyor_grid }
  archicad_submenu.add_item("Scanning Coordinates Grid Data") { GridGenerator.find_min_max_coordinates }
  
  grid_menu.add_separator
  grid_menu.add_item("Test Grid") { GridGenerator.create_test_grids }
  
  file_loaded(__FILE__)
end


puts "Grid Generator loaded!"
