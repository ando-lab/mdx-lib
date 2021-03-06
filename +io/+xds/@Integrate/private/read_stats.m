function stats = read_stats(fid)

template = struct(...
    'spot_pos_stdev',' STANDARD DEVIATION OF SPOT    POSITION (PIXELS) %f',...
    'spindle_pos_stdev',' STANDARD DEVIATION OF SPINDLE POSITION (DEGREES) %f',...
    'space_group_number',' SPACE GROUP NUMBER %d',...
    'unit_cell',' UNIT CELL PARAMETERS %f %f %f %f %f %f',...
    'a_axis',' COORDINATES OF UNIT CELL A-AXIS %f %f %f',...
    'b_axis',' COORDINATES OF UNIT CELL B-AXIS %f %f %f',...
    'c_axis',' COORDINATES OF UNIT CELL C-AXIS %f %f %f',...
    'crystal_rotation',' CRYSTAL ROTATION OFF FROM INITIAL ORIENTATION %f %f %f',...
    'crystal_mosaicity',' CRYSTAL MOSAICITY (DEGREES) %f',...
    'rotation_axis',' LAB COORDINATES OF ROTATION AXIS %f %f %f',...
    'direct_beam_coords',' DIRECT BEAM COORDINATES (REC. ANGSTROEM) %f %f %f',...
    'direct_beam_pixels',' DETECTOR COORDINATES (PIXELS) OF DIRECT BEAM %f %f',...
    'detector_origin_pixels',' DETECTOR ORIGIN (PIXELS) AT %f %f',...
    'f',' CRYSTAL TO DETECTOR DISTANCE (mm) %f');

stats = templated_read(fid,template);

end