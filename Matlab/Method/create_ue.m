function create_ue(sc, name, lat, lon)
    ue = sc.Children.New('eFacility', name);
    ue.Position.AssignGeodetic(lat, lon, 0);  
    ue.Graphics.LabelVisible = true;

    elevation = ue.AccessConstraints.AddConstraint('eCstrElevationAngle');
    elevation.EnableMin = 1;
    elevation.Min = 10;
end