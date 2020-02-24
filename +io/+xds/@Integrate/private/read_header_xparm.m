function xparm = read_header_xparm(fid)

template_geom = struct(...
    'space_group_number',' SPACE_GROUP_NUMBER= %d',...
    'unit_cell_constants',' UNIT_CELL_CONSTANTS= %f %f %f %f %f %f',...
    'rotation_axis',' ROTATION_AXIS= %f %f %f',...
    'oscillation_range',' OSCILLATION_RANGE= %f DEGREES',...
    'starting_angle_and_frame',' STARTING_ANGLE= %f STARTING_FRAME= %d',...
    'x_ray_wavelength',' X-RAY_WAVELENGTH= %f ANGSTROM',...
    'incident_beam_direction',' INCIDENT_BEAM_DIRECTION= %f %f %f');
template_detector = struct(...
    'number_of_detector_segments',' NUMBER OF DETECTOR SEGMENTS %d',...
    'nx_ny_qx_qy',' NX= %d NY= %d QX= %f QY= %f',...
    'orgx_orgy',' ORGX= %f ORGY= %f',...
    'detector_distance',' DETECTOR_DISTANCE= %f',...
    'direction_of_detector_x_axis',' DIRECTION_OF_DETECTOR_X-AXIS= %f %f %f',...
    'direction_of_detector_y_axis',' DIRECTION_OF_DETECTOR_Y-AXIS= %f %f %f');
template_segment = struct(...
    'seg_x1_x2_y1_y2',' SEGMENT= %d %d %d %d',...
    'seg_orgx_orgy',' SEGMENT_ORGX= %f SEGMENT_ORGY= %f',...
    'seg_distance',' SEGMENT_DISTANCE= %f',...
    'direction_of_segment_x_axis',' DIRECTION_OF_SEGMENT_X-AXIS= %f %f %f',...
    'direction_of_segment_y_axis',' DIRECTION_OF_SEGMENT_Y-AXIS= %f %f %f');

parm_geom = templated_read(fid,template_geom);
parm_detector = templated_read(fid,template_detector);

for j=1:parm_detector.number_of_detector_segments
    parm_segment(j) = templated_read(fid,template_segment);
end

xparm = header2xparm(parm_geom,parm_detector,parm_segment);

end