# Need to fix aux Kernels next  

#This edits the tutorial for the NNS project 


#  There are some renaming of blocks:  
# ram_spacer becomes cup / The graphite block that goes up to the ram has insets on both sides and the insets remind me of cups 
# cc_spacer becomes CFC / This stands for carbon-fiber composite
# sinter_spacer becomes spacer 
#
#
#    Since there are duplicates parts on the top and bottom of configuration blocks are named top_cup bot_CFC etc. 
#    This does add confusion with the default suffixes on MOOSE so they are changed to 
#     _top becomes _A 
#     _bottom becomes _B
#     _OD represents the outer diameter surface 
#     _ID represents the inner diameter surface. In this model it will be the ID of the spacer insets
#     _CL is the boundary for parts along the axis of symmetry
#     _SA represents surface area


# Demonstration simulation of standard DCS-5 run for MALAMUTE tutorial
#       Uses 2 rams, 2 cups, 2 spacers, 2 carbon-carbon spacers, 2 straight graphite punches, one die, and one sample _AG edit
#           sample takes material properties of fully densified material at simulation start
#       Geometry for all 6 spacers, the 2 punches, mold, and initial working sample volume
#           are defined in meters
#       The simulation is defined using axisymmetric RZ assumptions
#       Electric and thermal physics are included in the simulation, and a constant
#           interface pressure of 1.0 MPa
#
# BCs:
#    Potential:
#       (top electrode, top surface) --> Current as a function of time,
#                                        
#       (bottom electrode, bottom surface) = Ground
#       (elsewhere) --> natural boundary conditions (no current external to circuit)
#    Temperature:
#       (top electrode, top surface) = 300 K
#       (bottom electrode, bottom surface) = 300 K
#       (external right side of spacers, die wall) --> simple radiative BC into black body at 300 K
#       (external right side of punches, uncovered) --> simple radiative BC into black body at 300 K
#       (internal left side, along centerline) --> symmetry boundary conditions
# Modeling across interfaces uses the mortar contact, for both thermal and electrical:
#       (for contact with blocks touching) --> GapFluxModelPressureDependentConduction
#                                              A constant interface pressure of 1.0 MPa is prescribed
#       (for contact across gap filled with graphite foil)  --> GapFluxModelConduction
#       (for contact across gap, argon gas filled)  --> GapFluxModelConduction
# Initial Conditions:
#       Potential: 0 V
#       Temperature = 300 K


## Parameters for the standard DCS-5 geometry to build the mesh, units in meters
cup_radius = 0.031
cup_height = 0.018 # For this model the overhang is removed. The actual height is 17.75 but rounded the number
spacer_inset_radius = 0.010
spacer_overhang_height = 0.002

CFC_radius = 0.020
CFC_height = 0.00635

spacer_radius = 0.020
spacer_height = 0.027
spacer_overhang_radius = 0.010 ## is less than the 13.55 that actually exists to facilitate node matching in mesh building step
spacer_inset_depth = 0.002

punch_radius = 0.010
punch_height = 0.030

sample_OD = 0.020
sample_radius = ${fparse sample_OD/2}
sample_height = 0.00984

die_height = 0.040
die_ID = 0.020
die_inner_radius = ${fparse die_ID/2}

ram_height = 0.006
ram_OD = 0.05078 
ram_radius = ${fparse ram_OD/2}

###################################################################
# THIS IS THE MAIN PARAMETER OF INTEREST. We will eventually want to make die_thickness a function x(y) from -die_height to die_height
die_thickness = 0.0194 
###################################################################



#######################################################################################
### Calculated values from user-provided results
 ram_SA = ${fparse pi * ram_radius * ram_radius}
# # ram_spacer_overhang_offset = ${fparse cup_radius - spacer_inset_radius}
# ram_cc_spacers_height = ${fparse cup_height + CFC_height}
# ram_cc_sinter_spacers_height = ${fparse ram_cc_spacers_height + spacer_height}
# ram_cc_sinter_punch_height = ${fparse ram_cc_sinter_spacers_height + punch_height}
# die_wall_outer_radius = ${fparse die_inner_radfius + die_thickness}
# stack_with_powder = ${fparse ram_cc_sinter_punch_height + sample_height}

#    The block positioning is determined by y-positions variables of block. The blocks are built from the bottom up
#    each position uses the previous position variable 

# The order of components going from bottom to top is : bottom ram, bottom cup, bottom CFC, bottom spacer, bottom punch, sample, top punch, top spacer, top CFC, top cup, top ram
# with the die being at a y_pos equal to the center of the sample 

y_pos_bot_ram_B = 0 
y_pos_bot_ram_cup_interface = ${ram_height} 
y_pos_bot_cup_CFC_interface = ${fparse y_pos_bot_ram_cup_interface + cup_height}
y_pos_bot_CFC_spacer_interface = ${fparse y_pos_bot_cup_CFC_interface + CFC_height} 
y_pos_bot_spacer_punch_interface = ${fparse y_pos_bot_CFC_spacer_interface + spacer_height - spacer_inset_depth}
y_pos_bot_punch_sample_interface = ${fparse y_pos_bot_spacer_punch_interface + punch_height}
y_pos_center_of_sample_interface = ${fparse y_pos_bot_punch_sample_interface + sample_height/2}
y_pos_sample_top_punch_interface = ${fparse y_pos_bot_punch_sample_interface + sample_height}
y_pos_top_punch_spacer_interface = ${fparse y_pos_sample_top_punch_interface + punch_height - spacer_inset_depth}
y_pos_top_spacer_CFC_interface = ${fparse y_pos_top_punch_spacer_interface + spacer_height}
y_pos_top_CFC_cup_interface = ${fparse y_pos_top_spacer_CFC_interface + CFC_height}
y_pos_top_cup_ram_interface = ${fparse y_pos_top_CFC_cup_interface + cup_height}
y_pos_top_ram_A = ${fparse y_pos_top_cup_ram_interface + ram_height}
y_pos_die_bottom = ${fparse y_pos_center_of_sample_interface - die_height/2}
y_pos_die_top = ${fparse y_pos_center_of_sample_interface + die_height/2}


[Mesh] # NOTE : Need to check number of elements (nx and ny) with the dimensions
  [bot_ram] 
    type = GeneratedMeshGenerator
    dim = 2
    nx = 25
    ny = 6
    xmin = 0 # I realize xmin is default 0 but I think this helps with readability 
    xmax = ${ram_radius}
    ymin = 0 
    ymax = ${y_pos_bot_ram_cup_interface}
    boundary_name_prefix = bot_ram
    boundary_id_offset = 10
  []
  [bot_ram_block] 
    type = SubdomainIDGenerator
    input = 'bot_ram'
    subdomain_id = '1'
  []
  [bot_cup]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 31
    ny = 20
    xmax = ${cup_radius}
    ymin = ${y_pos_bot_ram_cup_interface}
    ymax = ${y_pos_bot_cup_CFC_interface}
    boundary_name_prefix = bot_cup
    boundary_id_offset = 20
    elem_type = QUAD8
  []
  [bot_cup_block]
    type = SubdomainIDGenerator
    input = 'bot_cup'
    subdomain_id = '2'
  []
  [bot_CFC]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 35
    ny = 7
    xmax = ${CFC_radius}
    ymin = ${y_pos_bot_cup_CFC_interface}
    ymax = ${y_pos_bot_CFC_spacer_interface}
    boundary_name_prefix = 'bot_CFC'
    boundary_id_offset = 30
    elem_type = QUAD8
  []
  [bot_CFC_block]
    type = SubdomainIDGenerator
    input = 'bot_CFC'
    subdomain_id = '3'
  []
  [bot_spacer]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 40
    ny = 27
    xmax = ${spacer_radius}
    ymin = ${y_pos_bot_CFC_spacer_interface}
    ymax = ${y_pos_bot_spacer_punch_interface}
    boundary_name_prefix = bot_spacer
    boundary_id_offset = 40
    elem_type = QUAD8
  []
  [bot_spacer_overhang]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 10
    ny = 2
    xmin = ${fparse spacer_radius - spacer_overhang_radius + 0.001}
    xmax = ${spacer_radius}
    ymin = ${y_pos_bot_spacer_punch_interface}
    ymax = ${fparse y_pos_bot_spacer_punch_interface + spacer_inset_depth}
    boundary_name_prefix = bot_spacer_overhang
    elem_type = QUAD8
    boundary_id_offset = 45
  []
  # [bot_spacer_boundary_rename]
  #   type = RenameBoundaryGenerator
  #   input = bot_spacer_overhang
  #   old_boundary = 'bot_spacer_overhang_left'
  #   new_boundary = 'bot_spacer_ID' # bottom spacer inner diameter of the inset hole
  # []  
  [bot_spacer_stitching]
    type = StitchedMeshGenerator
    inputs = 'bot_spacer bot_spacer_overhang'
    stitch_boundaries_pairs = 'bot_spacer_top bot_spacer_overhang_bottom' 
  []
  [bot_spacer_block]
    type = SubdomainIDGenerator
    input = 'bot_spacer_stitching'
    subdomain_id = '4'
  []
  [bot_punch]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 10
    ny = 24
    xmax = ${punch_radius}
    ymin = ${y_pos_bot_spacer_punch_interface}
    ymax = ${y_pos_bot_punch_sample_interface}
    boundary_name_prefix = 'bot_punch'
    elem_type = QUAD8
    boundary_id_offset = 50
  []
  [bot_punch_block]
    type = SubdomainIDGenerator
    input = bot_punch
    subdomain_id = 5
  []
  [sample]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 15
    ny = 18
    xmax = ${sample_radius}
    ymin = ${y_pos_bot_punch_sample_interface}
    ymax = ${y_pos_sample_top_punch_interface}
    boundary_name_prefix = sample
    elem_type = QUAD8
    boundary_id_offset = 70
  []
  [sample_block]
    type = SubdomainIDGenerator
    input = sample
    subdomain_id = 7
  []
  [top_punch]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 10
    ny = 24
    xmax = ${punch_radius}
    ymin = ${y_pos_sample_top_punch_interface}
    ymax = ${y_pos_top_punch_spacer_interface}
    boundary_name_prefix = 'top_punch'
    elem_type = QUAD8
    boundary_id_offset = 80
  []
  [top_punch_block]
    type = SubdomainIDGenerator
    input = top_punch
    subdomain_id = 8
  []
  [top_spacer_upper_section]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 40
    ny = 27
    xmax = ${spacer_radius}
    ymin = ${y_pos_top_punch_spacer_interface}
    ymax = ${y_pos_top_spacer_CFC_interface}
    boundary_name_prefix = top_spacer
    boundary_id_offset = 90
    elem_type = QUAD8
  []
  [top_spacer_overhang]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 10
    ny = 2
    xmin = ${fparse spacer_radius - spacer_overhang_radius + 0.001}
    xmax = ${spacer_radius}
    ymin = ${fparse y_pos_top_punch_spacer_interface - spacer_inset_depth}
    ymax = ${y_pos_top_punch_spacer_interface}
    boundary_name_prefix = top_spacer_overhang
    elem_type = QUAD8
    boundary_id_offset = 95
  []
  [top_spacer_boundary_rename]
    type = RenameBoundaryGenerator
    input = top_spacer_overhang
    old_boundary = 'top_spacer_overhang_left'
    new_boundary = 'top_spacer_ID'
  []
  [top_spacer]
    type = StitchedMeshGenerator
    inputs = 'top_spacer_upper_section top_spacer_boundary_rename'
    stitch_boundaries_pairs = 'top_spacer_bottom top_spacer_overhang_top'
  []
  [top_spacer_block]
    type = SubdomainIDGenerator
    input = 'top_spacer'
    subdomain_id = '9'
  []
  [top_CFC]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 35
    ny = 7
    xmax = ${CFC_radius}
    ymin = ${y_pos_top_spacer_CFC_interface}
    ymax = ${y_pos_top_CFC_cup_interface}
    boundary_name_prefix = 'top_CFC'
    boundary_id_offset = 100
    elem_type = QUAD8
  []
  [top_CFC_block]
    type = SubdomainIDGenerator
    input = 'top_CFC'
    subdomain_id = '10'
  []
  [top_cup]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 31
    ny = 20
    xmax = ${cup_radius}
    ymin = ${y_pos_top_CFC_cup_interface}
    ymax = ${y_pos_top_cup_ram_interface}
    boundary_name_prefix = top_cup
    elem_type = QUAD8
    boundary_id_offset = 110
  []
  [top_cup_block]
    type = SubdomainIDGenerator
    input = 'top_cup'
    subdomain_id = '11'
  []
  [top_ram] 
    type = GeneratedMeshGenerator
    dim = 2
    nx = 25
    ny = 6
    xmin = 0 # I realize xmin is default 0 but I think this helps with readability 
    xmax = ${ram_radius}
    ymin = ${y_pos_top_cup_ram_interface} 
    ymax = ${y_pos_top_ram_A}
    boundary_name_prefix = top_ram
    boundary_id_offset = 120
  []
  [top_ram_block] 
    type = SubdomainIDGenerator
    input = 'top_ram'
    subdomain_id = '12'
  []
  [die]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 14
    ny = 30
    xmin = ${die_inner_radius}
    xmax = ${fparse die_inner_radius + die_thickness}
    ymin = ${y_pos_die_bottom}
    ymax = ${y_pos_die_top}
    boundary_name_prefix = die
    elem_type = QUAD8
    boundary_id_offset = 60
  []
  [die_block]
    type = SubdomainIDGenerator
    input = 'die'
    subdomain_id = 6
  []

  [twelve_blocks]
    type = MeshCollectionGenerator
    inputs = 'bot_ram_block bot_cup_block bot_CFC_block bot_spacer_block
              bot_punch_block die_block sample_block top_punch_block top_spacer_block
              top_CFC_block top_cup_block top_ram_block'
  []
  [block_rename]
    type = RenameBlockGenerator
    input = twelve_blocks
    old_block = '1 2 3 4 5 6 7 8 9 10 11 12'
    new_block = 'bot_ram bot_cup bot_CFC bot_spacer bot_punch die
                 sample top_punch top_spacer top_CFC top_cup top_ram'
  []
  [uncovered_bottom_punch_right]
    type = SideSetsFromBoundingBoxGenerator
    input = block_rename
    bottom_left = '${fparse punch_radius - 1.0e-3} ${fparse y_pos_bot_spacer_punch_interface + spacer_inset_depth - 1.0e-4} 0.0'
    top_right = '${fparse punch_radius + 1.0e-3} ${fparse y_pos_die_bottom + 1.0e-4} 0.0'
    boundary_new = 'uncovered_bottom_punch_right'
    included_boundaries = 'bot_punch_right'
  []
  [uncovered_top_punch_right]
    type = SideSetsFromBoundingBoxGenerator
    input = uncovered_bottom_punch_right
    bottom_left = '${fparse punch_radius - 1.0e-3} ${fparse y_pos_die_top + 1.0e-4} 0.0'
    top_right = '${fparse punch_radius + 1.0e-3} ${fparse y_pos_top_punch_spacer_interface - spacer_inset_depth + 1.0e-4} 0.0'
    boundary_new = 'uncovered_top_punch_right'
    included_boundaries = 'top_punch_right'
  []
  # Adding sidesets for top and bottom spacer ID contact to punch
  # [top_punch_to_spacer_ID]
  #   type = SideSetsFromBoundingBoxGenerator
  #   input = uncovered_top_punch_right
  #   bottom_left = '${fparse spacer_inset_radius - 1.0e-3} ${fparse y_pos_top_punch_spacer_interface - spacer_inset_depth - 1.0e-4} 0.0'
  #   top_right = '${fparse spacer_inset_radius + 1.0e-3} ${fparse y_pos_top_punch_spacer_interface + 1.0e-4} 0.0'
  #   boundary_new = 'top_punch_to_spacer_ID'
  #   included_boundaries = 'top_punch_right'
  # []
  # [bot_punch_to_spacer_ID]
  #   type = SideSetsFromBoundingBoxGenerator
  #   input = top_punch_to_spacer_ID
  #   bottom_left = '${fparse spacer_inset_radius - 1.0e-3} ${fparse y_pos_bot_spacer_punch_interface - 1.0e-4} 0.0'
  #   top_right = '${fparse spacer_inset_radius + 1.0e-3} ${fparse y_pos_bot_spacer_punch_interface + spacer_inset_depth + 1.0e-4} 0.0'
  #   boundary_new = 'bot_punch_to_spacer_ID'
  #   included_boundaries = 'bot_punch_right' 
  #   []   
  [bot_ram_A_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_ram_top'
    new_block_id = 110 
    new_block_name = 'bot_ram_A_primary_subdomain'
    input = 'uncovered_top_punch_right'
  []
  [bot_cup_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_cup_bottom'
    new_block_id = 211
    new_block_name = 'bot_cup_B_secondary_subdomain'
    input = bot_ram_A_primary_subdomain
  []
  [bot_cup_A_primary_subdomain] 
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_cup_top'
    new_block_id = 210
    new_block_name = 'bot_cup_A_primary_subdomain'
    input = bot_cup_B_secondary_subdomain
  []
  [bot_CFC_B_secondary_subdomain] 
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_CFC_bottom'
    new_block_id = 311
    new_block_name = 'bot_CFC_B_secondary_subdomain' # bot_CFC_B_secondary_subdomain
    input = bot_cup_A_primary_subdomain
  []
  [bot_CFC_A_primary_subdomain] # bot_CFC_A_primary_subdomain
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_CFC_top'
    new_block_id = 310
    new_block_name = 'bot_CFC_A_primary_subdomain'
    input = bot_CFC_B_secondary_subdomain
  []
  [bot_spacer_B_secondary_subdomain] 
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_spacer_bottom'
    new_block_id = 411
    new_block_name = 'bot_spacer_B_secondary_subdomain'
    input = bot_CFC_A_primary_subdomain
  []
  [bot_spacer_A_primary_subdomain] 
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_spacer_top'
    new_block_id = 410
    new_block_name = 'bot_spacer_A_primary_subdomain'
    input = bot_spacer_B_secondary_subdomain
  []
  [bot_punch_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_punch_bottom'
    new_block_id = 511
    new_block_name = 'bot_punch_B_secondary_subdomain'
    input = bot_spacer_A_primary_subdomain
  []
  [bot_punch_A_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_punch_top'
    new_block_id = 510
    new_block_name = 'bot_punch_A_primary_subdomain'
    input = bot_punch_B_secondary_subdomain
  []
  [sample_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'sample_bottom'
    new_block_id = 711
    new_block_name = 'sample_B_secondary_subdomain'
    input = bot_punch_A_primary_subdomain
  []
  [sample_A_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'sample_top'
    new_block_id = 710
    new_block_name = 'sample_A_primary_subdomain'
    input = sample_B_secondary_subdomain
  []
  [top_punch_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_punch_bottom'
    new_block_id = 811
    new_block_name = 'top_punch_B_secondary_subdomain'
    input = sample_A_primary_subdomain
  []
  [top_punch_A_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_punch_top'
    new_block_id = 810
    new_block_name = 'top_punch_A_primary_subdomain'
    input = top_punch_B_secondary_subdomain
  []
  [top_spacer_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_spacer_bottom'
    new_block_id = 911
    new_block_name = 'top_spacer_B_secondary_subdomain'
    input = top_punch_A_primary_subdomain
  []
  [top_spacer_A_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_spacer_top'
    new_block_id = 910
    new_block_name = 'top_spacer_A_primary_subdomain'
    input = top_spacer_B_secondary_subdomain
  []
  [top_CFC_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_CFC_bottom'
    new_block_id = 1011
    new_block_name = 'top_CFC_B_secondary_subdomain'
    input = top_spacer_A_primary_subdomain
  []
  [top_CFC_A_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_CFC_top'
    new_block_id = 1010
    new_block_name = 'top_CFC_A_primary_subdomain'
    input = top_CFC_B_secondary_subdomain
  []
  [top_cup_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_cup_bottom'
    new_block_id = 1111
    new_block_name = 'top_cup_B_secondary_subdomain'
    input = top_CFC_A_primary_subdomain
  []
  [top_cup_A_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_cup_top'
    new_block_id = 1110
    new_block_name = 'top_cup_A_primary_subdomain'
    input = top_cup_B_secondary_subdomain
  []
  [top_ram_B_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_ram_bottom'
    new_block_id = 1211
    new_block_name = 'top_ram_B_secondary_subdomain'
    input = top_cup_A_primary_subdomain
  []
  [die_ID_primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'die_left'
    new_block_id = 612
    new_block_name = 'die_ID_primary_subdomain'
    input = top_ram_B_secondary_subdomain
  []
  [bot_punch_right_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'bot_punch_right'
    new_block_id = 412
    new_block_name = 'bot_punch_right_secondary_subdomain'
    input = die_ID_primary_subdomain
  []
  [sample_OD_secondary_subdomain] 
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'sample_right'
    new_block_id = 514
    new_block_name = 'sample_OD_secondary_subdomain'
    input = bot_punch_right_secondary_subdomain
  []
  [inside_top_punch_secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    sidesets = 'top_punch_right'
    new_block_id = 614
    new_block_name = 'inside_top_punch_secondary_subdomain'
    input = sample_OD_secondary_subdomain
  []

  # __ This is for surface to surface radiation ________________________________________________________

  # [gap_bottom_sinter_die_primary_subdomain]
  #   type = LowerDBlockFromSidesetGenerator
  #   sidesets = 'bottom_sinter_spacer_overhang_top'
  #   new_block_id = 3111
  #   new_block_name = 'gap_bottom_sinter_die_primary_subdomain'
  #   input = inside_top_punch_secondary_subdomain
  # []
  # [gap_bottom_sinter_die_secondary_subdomain]
  #   type = LowerDBlockFromSidesetGenerator
  #   sidesets = 'die_wall_bottom'
  #   new_block_id = 1022
  #   new_block_name = 'gap_bottom_sinter_die_secondary_subdomain'
  #   input = gap_bottom_sinter_die_primary_subdomain
  # []
  # [gap_top_sinter_die_primary_subdomain]
  #   type = LowerDBlockFromSidesetGenerator
  #   sidesets = 'top_sinter_spacer_overhang_bottom'
  #   new_block_id = 7222
  #   new_block_name = 'gap_top_sinter_die_primary_subdomain'
  #   input = gap_bottom_sinter_die_secondary_subdomain
  # []
  # [gap_top_sinter_die_secondary_subdomain]
  #   type = LowerDBlockFromSidesetGenerator
  #   sidesets = 'die_wall_top'
  #   new_block_id = 1011
  #   new_block_name = 'gap_top_sinter_die_secondary_subdomain'
  #   input = gap_top_sinter_die_primary_subdomain
  # []
 #__________________________________________________________



  patch_update_strategy = iteration
  second_order = true
  coord_type = RZ
[]

[Problem]
  type = ReferenceResidualProblem
  reference_vector = 'ref'
  extra_tag_vectors = 'ref'
  converge_on = 'temperature potential'
[]

[Variables]
  [temperature]
    initial_condition = 300.0
    block = 'bot_ram bot_cup bot_CFC bot_spacer bot_punch
             sample top_punch top_spacer top_CFC top_cup die top_ram'
    order = SECOND
  []
  [potential]
    block = 'bot_ram bot_cup bot_CFC bot_spacer bot_punch
             sample top_punch top_spacer top_CFC top_cup die top_ram'
    order = SECOND
  []
  [temperature_bot_cup_B_lm]
    block = 'bot_cup_B_secondary_subdomain'
    order = SECOND
  []
  [potential_bot_cup_B_lm]
    block = 'bot_cup_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_bot_CFC_B_lm] 
    block = 'bot_CFC_B_secondary_subdomain' 
    order = SECOND
  []
  [potential_bot_CFC_B_lm]
    block = 'bot_CFC_B_secondary_subdomain' # bot_CFC_B_secondary_subdomain
    order = SECOND
  []
  [temperature_bot_spacer_B_lm]
    block = 'bot_spacer_B_secondary_subdomain'
    order = SECOND
  []
  [potential_bot_spacer_B_lm]
    block = 'bot_spacer_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_bot_punch_B_lm]
    block = 'bot_punch_B_secondary_subdomain'
    order = SECOND
  []
  [potential_bot_punch_B_lm]
    block = 'bot_punch_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_sample_B_lm]
    block = ' sample_B_secondary_subdomain'
    order = SECOND
  []
  [potential_sample_B_lm]
    block = 'sample_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_top_punch_B_lm]
    block = 'top_punch_B_secondary_subdomain'
    order = SECOND
  []
  [potential_top_punch_B_lm]
    block = ' top_punch_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_top_spacer_B_lm]
    block = 'top_spacer_B_secondary_subdomain'
    order = SECOND
  []
  [potential_top_spacer_B_lm]
    block = 'top_spacer_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_top_CFC_B_lm]
    block = 'top_CFC_B_secondary_subdomain'
    order = SECOND
  []
  [potential_top_CFC_B_lm]
    block = 'top_CFC_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_top_cup_B_lm]
    block = 'top_cup_B_secondary_subdomain'
    order = SECOND
  []
  [potential_top_cup_B_lm]
    block = 'top_cup_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_top_ram_B_lm]
    block = 'top_ram_B_secondary_subdomain'
    order = SECOND
  []
  [potential_top_ram_B_lm]
    block = 'top_ram_B_secondary_subdomain'
    order = SECOND
  []
  [temperature_inside_low_punch_lm]
    block = 'bot_punch_right_secondary_subdomain'
    order = SECOND
  []
  [potential_inside_low_punch_lm]
    block = 'bot_punch_right_secondary_subdomain'
    order = SECOND
  []
  [temperature_sample_OD_lm]
    block = 'sample_OD_secondary_subdomain'
    order = SECOND
  []
  [potential_sample_OD_lm]
    block = 'sample_OD_secondary_subdomain'
    order = SECOND
  []
  [temperature_inside_top_punch_lm]
    block = 'inside_top_punch_secondary_subdomain'
    order = SECOND
  []
  [potential_inside_top_punch_lm]
    block = 'inside_top_punch_secondary_subdomain'
    order = SECOND
  []
  # [temperature_gap_top_sinter_die_lm]                       # This is for when using surface to surface radiation
  #   block = 'gap_top_sinter_die_secondary_subdomain'
  #   order = SECOND
  # []
  # [temperature_gap_bottom_sinter_die_lm]
  #   block = 'gap_bottom_sinter_die_secondary_subdomain'
  #   order = SECOND
  # []
[]

[AuxVariables]
  [heat_transfer_radiation]
    order = SECOND
  []

  [electric_field_x]
    family = MONOMIAL #prettier pictures with smoother values
    order = FIRST
    block = 'bot_ram bot_cup bot_CFC bot_spacer bot_punch
             sample top_punch top_spacer top_CFC top_cup top_ram die'
  []
  [electric_field_y]
    family = MONOMIAL
    order = FIRST
    block = 'bot_ram bot_cup bot_CFC bot_spacer bot_punch
             sample top_punch top_spacer top_CFC top_cup top_ram die'
  []

  [interface_normal_lm] # Needs change
    order = FIRST
    family = LAGRANGE
    block = 'bot_cup_B_secondary_subdomain  bot_CFC_B_secondary_subdomain bot_spacer_B_secondary_subdomain
             bot_punch_B_secondary_subdomain sample_B_secondary_subdomain
             top_punch_B_secondary_subdomain top_spacer_B_secondary_subdomain
             top_CFC_B_secondary_subdomain top_cup_B_secondary_subdomain top_ram_B_secondary_subdomain
             bot_punch_right_secondary_subdomain sample_OD_secondary_subdomain
             inside_top_punch_secondary_subdomain'
    initial_condition = 1.0e6
  []
[]

[Kernels]
  [HeatDiff_graphite]
    type = ADHeatConduction
    variable = temperature
    thermal_conductivity = graphite_thermal_conductivity
    extra_vector_tags = 'ref'
    block = 'bot_cup bot_spacer bot_punch
             top_punch top_spacer top_cup die'
  []
  [HeatTdot_graphite]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = graphite_heat_capacity
    density_name = graphite_density
    extra_vector_tags = 'ref'
    block = 'bot_cup bot_spacer bot_punch
             top_punch top_spacer top_cup die'
  []
  [electric_graphite]
    type = ADMatDiffusion
    variable = potential
    diffusivity = graphite_electrical_conductivity
    extra_vector_tags = 'ref'
    block = 'bot_cup bot_spacer bot_punch
             top_punch top_spacer top_cup die'
  []
  [JouleHeating_graphite]
    type = ADJouleHeatingSource
    variable = temperature
    elec = potential
    electrical_conductivity = graphite_electrical_conductivity
    # use_displaced_mesh = true
    extra_vector_tags = 'ref'
    block = 'bot_cup bot_spacer bot_punch
             top_punch top_spacer top_cup die'
  []

  [HeatDiff_anistropic_carbon_fiber]
    type = ADMatAnisoDiffusion
    diffusivity = ccfiber_aniso_thermal_conductivity
    variable = temperature
    extra_vector_tags = 'ref'
    block = 'bot_CFC top_CFC'
  []
  [HeatTdot_carbon_fiber]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = ccfiber_heat_capacity
    density_name = ccfiber_density
    extra_vector_tags = 'ref'
    block = 'bot_CFC top_CFC'
  []
  [electric_carbon_fiber]
    type = ADMatDiffusion
    variable = potential
    diffusivity = ccfiber_electrical_conductivity
    extra_vector_tags = 'ref'
    block = 'bot_CFC top_CFC'
  []
  [JouleHeating_carbon_fiber]
    type = ADJouleHeatingSource
    variable = temperature
    elec = potential
    electrical_conductivity = ccfiber_electrical_conductivity
    # use_displaced_mesh = true
    extra_vector_tags = 'ref'
    block = 'bot_CFC top_CFC'
  []

  [HeatDiff_powder]
    type = ADHeatConduction
    variable = temperature
    thermal_conductivity = copper_thermal_conductivity
    extra_vector_tags = 'ref'
    block = 'sample'
  []
  [HeatTdot_powder]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = copper_heat_capacity
    density_name = copper_density
    extra_vector_tags = 'ref'
    block = 'sample'
  []
  [electric_powder]
    type = ADMatDiffusion
    variable = potential
    diffusivity = copper_electrical_conductivity
    extra_vector_tags = 'ref'
    block = 'sample'
  []
  [JouleHeating_powder]
    type = ADJouleHeatingSource
    variable = temperature
    elec = potential
    electrical_conductivity = copper_electrical_conductivity
    # use_displaced_mesh = true
    extra_vector_tags = 'ref'
    block = 'sample'
  []
[]

[AuxKernels]
  [heat_transfer_radiation]
    type = ParsedAux
    variable = heat_transfer_radiation
    boundary = 'bottom_ram_spacer_right bottom_ram_spacer_overhang_right bottom_cc_spacer_right
                bottom_sinter_spacer_right bottom_sinter_spacer_overhang_right uncovered_bottom_punch_right
                top_sinter_spacer_overhang_right top_sinter_spacer_right die_wall_right uncovered_top_punch_right
                top_cc_spacer_right top_cup_overhang_right top_cup_right'
    coupled_variables = 'temperature'
    constant_names = 'boltzmann epsilon temperature_farfield' #published emissivity for graphite is 0.85
    constant_expressions = '5.67e-8 0.85 300.0' #roughly room temperature, which is probably too cold
    expression = '-boltzmann*epsilon*(temperature^4-temperature_farfield^4)'
  []

  [electrostatic_calculation_x]
    type = PotentialToFieldAux
    gradient_variable = potential
    variable = electric_field_x
    sign = negative
    component = x
    block = 'bot_ram bot_cup bot_CFC bot_spacer bot_punch
             sample top_punch top_spacer top_CFC top_cup die top_ram'
  []
  [electrostatic_calculation_y]
    type = PotentialToFieldAux
    gradient_variable = potential
    variable = electric_field_y
    sign = negative
    component = y
    block = 'bot_ram bot_cup bot_CFC bot_spacer bot_punch
             sample top_punch top_spacer top_CFC top_cup die top_ram'
  []
[]

[Functions]
  [current_application]
    type = PiecewiseLinear
    x = '0            40                                    60                                   160                                   200                                   230                                   340                                   850                                   890                                   900                                   950                                   1010                                  1050                                  1100                                  1200                                  1240                                1250                        1260 1800'
    y = '0  ${fparse 561/ram_SA} ${fparse 502/ram_SA} ${fparse 500/ram_SA} ${fparse 417/ram_SA} ${fparse 417/ram_SA} ${fparse 566/ram_SA} ${fparse 952/ram_SA} ${fparse 926/ram_SA} ${fparse 926/ram_SA} ${fparse 977/ram_SA}  ${fparse 902/ram_SA} ${fparse 902/ram_SA} ${fparse 927/ram_SA} ${fparse 926/ram_SA} ${fparse 903/ram_SA} ${fparse 4/ram_SA}  0    0'
    scale_factor = 1.0
  []
[]

[BCs]
  [temperature_rams]
    type = ADDirichletBC
    variable = temperature
    value = 300.0
    boundary = 'top_ram_top bot_ram_bottom'
  []
  [external_surface_temperature] # may need to specify sidesets that on top and bottom of cup spacer that are open to air 
    type = CoupledVarNeumannBC
    variable = temperature
    v = heat_transfer_radiation
    boundary = 'bot_ram_right bot_cup_right bot_CFC_right bot_spacer_right 
                uncovered_bottom_punch_right die_bottom die_right die_top 
                uncovered_top_punch_right top_CFC_right top_cup_right top_ram_right ' 
  []
  [electric_top]
    type = ADFunctionNeumannBC
    variable = potential
    function = 'current_application'
    boundary = 'top_ram_top'
  []
  [electric_bottom]
    type = ADDirichletBC
    variable = potential
    value = 0.0
    boundary = 'bot_ram_bottom'
  []
[]

[Constraints]
  [thermal_contact_interface_bot_ram_bot_cup]
    type = ModularGapConductanceConstraint
    variable = temperature_bot_cup_B_lm
    secondary_variable = temperature
    primary_boundary = bot_cup_bottom
    primary_subdomain = bot_cup_A_primary_subdomain
    secondary_boundary = bot_ram_top
    secondary_subdomain = bot_ram_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_bot_cup_bot_CFC' # need to change in User
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_bot_ram_bot_cup]
    type = ModularGapConductanceConstraint
    variable = potential_bot_CFC_B_lm
    secondary_variable = potential
    primary_boundary = bot_cup_top
    primary_subdomain = bot_cup_A_primary_subdomain
    secondary_boundary = bot_CFC_bottom
    secondary_subdomain = bot_CFC_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electrical_interface_bot_ram_bot_cup'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_interface_bot_cup_bot_CFC]
    type = ModularGapConductanceConstraint
    variable = temperature_bot_CFC_B_lm
    secondary_variable = temperature
    primary_boundary = bot_cup_top
    primary_subdomain = bot_cup_A_primary_subdomain
    secondary_boundary = bot_CFC_bottom
    secondary_subdomain = bot_CFC_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_bot_cup_bot_CFC'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_bot_cup_bot_CFC]
    type = ModularGapConductanceConstraint
    variable = potential_bot_CFC_B_lm
    secondary_variable = potential
    primary_boundary = bot_cup_top
    primary_subdomain = bot_cup_A_primary_subdomain
    secondary_boundary = bot_CFC_bottom
    secondary_subdomain = bot_CFC_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electrical_interface_bot_ram_bot_cup'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_bot_CFC_bot_spacer]
    type = ModularGapConductanceConstraint
    variable = temperature_bot_spacer_B_lm
    secondary_variable = temperature
    primary_boundary = bot_CFC_top
    primary_subdomain = bot_CFC_A_primary_subdomain
    secondary_boundary = bot_spacer_bottom
    secondary_subdomain = bot_spacer_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_bottom_cc_sinter'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_bot_CFC_bot_spacer]
    type = ModularGapConductanceConstraint
    variable = potential_bot_spacer_B_lm
    secondary_variable = potential
    primary_boundary = bot_CFC_top
    primary_subdomain = bot_CFC_A_primary_subdomain
    secondary_boundary = bot_spacer_bottom
    secondary_subdomain = bot_spacer_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electric_interface_bottom_cc_sinter'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_interface_bot_spacer_bot_punch]
    type = ModularGapConductanceConstraint
    variable = temperature_bot_punch_B_lm
    secondary_variable = temperature
    primary_boundary = bot_spacer_top
    primary_subdomain = bot_spacer_A_primary_subdomain
    secondary_boundary = bot_punch_bottom
    secondary_subdomain = bot_punch_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_bottom_sinter_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_bot_spacer_bot_punch]
    type = ModularGapConductanceConstraint
    variable = potential_bot_punch_B_lm
    secondary_variable = potential
    primary_boundary = bot_spacer_top
    primary_subdomain = bot_spacer_A_primary_subdomain
    secondary_boundary = bot_punch_bottom
    secondary_subdomain = bot_punch_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electric_interface_bottom_sinter_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_interface_bot_punch_sample]
    type = ModularGapConductanceConstraint
    variable = temperature_sample_B_lm
    secondary_variable = temperature
    primary_boundary = bot_punch_top
    primary_subdomain = bot_punch_A_primary_subdomain
    secondary_boundary = sample_bottom
    secondary_subdomain = sample_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_bottom_punch_powder'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_bot_punch_sample]
    type = ModularGapConductanceConstraint
    variable = potential_sample_B_lm
    secondary_variable = potential
    primary_boundary = bot_punch_top
    primary_subdomain = bot_punch_A_primary_subdomain
    secondary_boundary = sample_bottom
    secondary_subdomain = sample_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electric_interface_bottom_punch_powder'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_interface_sample_top_punch]
    type = ModularGapConductanceConstraint
    variable = temperature_top_punch_B_lm
    secondary_variable = temperature
    primary_boundary = sample_top
    primary_subdomain = sample_A_primary_subdomain
    secondary_boundary = top_punch_bottom
    secondary_subdomain = top_punch_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_powder_top_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_sample_top_punch]
    type = ModularGapConductanceConstraint
    variable = potential_top_punch_B_lm
    secondary_variable = potential
    primary_boundary = sample_top
    primary_subdomain = sample_A_primary_subdomain
    secondary_boundary = top_punch_bottom
    secondary_subdomain = top_punch_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electric_interface_powder_top_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_top_punch_top_spacer]
    type = ModularGapConductanceConstraint
    variable = temperature_top_spacer_B_lm
    secondary_variable = temperature
    primary_boundary = top_punch_top
    primary_subdomain = top_punch_A_primary_subdomain
    secondary_boundary = top_spacer_bottom
    secondary_subdomain = top_spacer_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_top_punch_sinter'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_top_punch_top_spacer]
    type = ModularGapConductanceConstraint
    variable = potential_top_spacer_B_lm
    secondary_variable = potential
    primary_boundary = top_punch_top
    primary_subdomain = top_punch_A_primary_subdomain
    secondary_boundary = top_spacer_bottom
    secondary_subdomain = top_spacer_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electric_interface_top_punch_sinter'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_top_spacer_top_CFC]
    type = ModularGapConductanceConstraint
    variable = temperature_top_CFC_B_lm
    secondary_variable = temperature
    primary_boundary = top_spacer_top
    primary_subdomain = top_spacer_A_primary_subdomain
    secondary_boundary = top_CFC_bottom
    secondary_subdomain = top_CFC_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_top_sinter_cc_spacer'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_top_spacer_top_CFC]
    type = ModularGapConductanceConstraint
    variable = potential_top_CFC_B_lm
    secondary_variable = potential
    primary_boundary = top_spacer_top
    primary_subdomain = top_spacer_A_primary_subdomain
    secondary_boundary = top_CFC_bottom
    secondary_subdomain = top_CFC_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electric_interface_top_sinter_cc_spacer'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_top_CFC_top_cup]
    type = ModularGapConductanceConstraint
    variable = temperature_top_cup_B_lm
    secondary_variable = temperature
    primary_boundary = top_CFC_top
    primary_subdomain = top_CFC_A_primary_subdomain
    secondary_boundary = top_cup_bottom
    secondary_subdomain = top_cup_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_thermal_interface_top_cc_ram_spacer'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_top_CFC_top_cup]
    type = ModularGapConductanceConstraint
    variable = potential_top_cup_B_lm
    secondary_variable = potential
    primary_boundary = top_CFC_top
    primary_subdomain = top_CFC_A_primary_subdomain
    secondary_boundary = top_cup_bottom
    secondary_subdomain = top_cup_B_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'closed_electric_interface_top_cc_ram_spacer'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_interface_inside_die_low_punch]
    type = ModularGapConductanceConstraint
    variable = temperature_inside_low_punch_lm
    secondary_variable = temperature
    primary_boundary = die_left
    primary_subdomain = die_ID_primary_subdomain
    secondary_boundary = bot_punch_right
    secondary_subdomain = bot_punch_right_secondary_subdomain
    gap_geometry_type = CYLINDER
    gap_flux_models = 'thermal_conduction_wall_low_punch closed_thermal_interface_inside_die_low_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_inside_die_low_punch]
    type = ModularGapConductanceConstraint
    variable = potential_inside_low_punch_lm
    secondary_variable = potential
    primary_boundary = die_left
    primary_subdomain = die_ID_primary_subdomain
    secondary_boundary = bot_punch_right
    secondary_subdomain = bot_punch_right_secondary_subdomain
    gap_geometry_type = CYLINDER
    gap_flux_models = 'electrical_conduction_wall_low_punch closed_electric_interface_inside_die_low_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_interface_inside_die_powder]
    type = ModularGapConductanceConstraint
    variable = temperature_sample_OD_lm
    secondary_variable = temperature
    primary_boundary = die_left
    primary_subdomain = die_ID_primary_subdomain
    secondary_boundary = sample_right
    secondary_subdomain = sample_OD_secondary_subdomain
    gap_geometry_type = CYLINDER
    gap_flux_models = 'thermal_conduction_wall_powder closed_thermal_interface_inside_die_powder'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_inside_die_powder]
    type = ModularGapConductanceConstraint
    variable = potential_sample_OD_lm
    secondary_variable = potential
    primary_boundary = die_left
    primary_subdomain = die_ID_primary_subdomain
    secondary_boundary = sample_right
    secondary_subdomain = sample_OD_secondary_subdomain
    gap_geometry_type = CYLINDER
    gap_flux_models = 'electrical_conduction_wall_powder closed_electric_interface_inside_die_powder'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [thermal_contact_interface_inside_die_top_punch]
    type = ModularGapConductanceConstraint
    variable = temperature_inside_top_punch_lm
    secondary_variable = temperature
    primary_boundary = die_left
    primary_subdomain = die_ID_primary_subdomain
    secondary_boundary = top_punch_right
    secondary_subdomain = inside_top_punch_secondary_subdomain
    gap_geometry_type = CYLINDER
    gap_flux_models = 'thermal_conduction_wall_top_punch closed_thermal_interface_inside_die_top_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  [electrical_contact_interface_inside_die_top_punch]
    type = ModularGapConductanceConstraint
    variable = potential_inside_top_punch_lm
    secondary_variable = potential
    primary_boundary = die_left
    primary_subdomain = die_ID_primary_subdomain
    secondary_boundary = top_punch_right
    secondary_subdomain = inside_top_punch_secondary_subdomain
    gap_geometry_type = CYLINDER
    gap_flux_models = 'electrical_conduction_wall_top_punch closed_electric_interface_inside_die_top_punch'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
  # [thermal_gap_contact_interface_bottom_sinter_die]
  #   type = ModularGapConductanceConstraint
  #   variable = temperature_gap_bottom_sinter_die_lm
  #   secondary_variable = temperature
  #   primary_boundary = bottom_sinter_spacer_overhang_top
  #   primary_subdomain = gap_bottom_sinter_die_primary_subdomain
  #   secondary_boundary = die_wall_bottom
  #   secondary_subdomain = gap_bottom_sinter_die_secondary_subdomain
  #   gap_geometry_type = PLATE
  #   gap_flux_models = 'gap_thermal_interface_bottom_sinter_die'
  #   extra_vector_tags = 'ref'
  #   correct_edge_dropping = true
  #   # use_displaced_mesh = true
  # []
  [thermal_gap_contact_interface_top_sinter_die]
    type = ModularGapConductanceConstraint
    variable = temperature_gap_top_sinter_die_lm
    secondary_variable = temperature
    primary_boundary = top_sinter_spacer_overhang_bottom
    primary_subdomain = gap_top_sinter_die_primary_subdomain
    secondary_boundary = die_wall_top
    secondary_subdomain = gap_top_sinter_die_secondary_subdomain
    gap_geometry_type = PLATE
    gap_flux_models = 'gap_thermal_interface_top_sinter_die'
    extra_vector_tags = 'ref'
    correct_edge_dropping = true
    # use_displaced_mesh = true
  []
[]

[Materials]
  [graphite_electro_thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'graphite_density graphite_thermal_conductivity graphite_heat_capacity graphite_electrical_conductivity graphite_hardness'
    prop_values = '        1.82e3           81                            1.303e3                5.88e4                           1.0'
    block = 'bot_cup bot_spacer bot_punch
             top_punch top_spacer top_cup die
             bot_spacer_B_secondary_subdomain bot_punch_B_secondary_subdomain
             top_spacer_B_secondary_subdomain top_cup_B_secondary_subdomain
             bot_punch_right_secondary_subdomain inside_top_punch_secondary_subdomain'
    # density (kg/m^3), thermal conductivity (W/m-K), and electrical conductivity (S/m) from manufacture datasheet for G535,
    #           available at http://schunk-tokai.pl/pl/wp-content/uploads/Schunk-Tokai-2015-englisch.pdf
    # specific heat capacity for IG110 graphite, https://www.nrc.gov/docs/ML2121/ML21215A346.pdf, equation on pg A-40 at 293K,
  []
  [carbon_fiber_electro_thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'ccfiber_density ccfiber_thermal_conductivity ccfiber_heat_capacity ccfiber_electrical_conductivity ccfiber_hardness'
    prop_values = ' 1.5e3                 5.0                     1.25e3                   4.0e4                           1.0'
    block = 'bot_CFC top_CFC bot_CFC_B_secondary_subdomain  # bot_CFC_B_secondary_subdomaintop_sinter_cc_secondary_subdomain'
    # density (kg/m^3) and electrical conductivity (S/m) from Schunk CF226 manufacturer's datasheet, available at http://schunk-tokai.pl/en/wp-content/uploads/e_CF-226.pdf
    # thermal conductivity (W/m-K), perpendicular to fiber direction, from Schunk CF226 manufacturer's datasheet, available at http://schunk-tokai.pl/en/wp-content/uploads/e_CF-226.pdf
    # specific heat capacity (J/kg-K) from Sommers et al. App. Thermal Engineering 30(11-12) (2010) 1277-1291 for Schunk FU2952
    # hardness set to unity to remove dependence on that quantity
  []
  [carbon_fiber_anisotropic_thermal_cond]
    type = ADConstantAnisotropicMobility
    tensor = '40 0 0
              0  5 0
              0  0 40'
    M_name = ccfiber_aniso_thermal_conductivity
    # data sourced from Schunk CF226 manufacturer's datasheet, available at http://schunk-tokai.pl/en/wp-content/uploads/e_CF-226.pdf
  []
  [copper_electro_thermal_properties]
    type = ADGenericConstantMaterial
    prop_names = 'copper_density copper_thermal_conductivity copper_heat_capacity copper_electrical_conductivity copper_hardness'
    prop_values = ' 8.96e3            401.2                     0.385e3             5.8e7                      1.0'
    # all properties assume fully dense copper
    # density (kg/m^3) and heat capacity (J/kg-K) from Stevens and Boerio-Goates. J. Chem. Thermodaynamics 36(10) 857-863(2004)
    # thermal conductivity (W/m-K) and electrical conductivity (S/m) from Moore, McElroy, and Graves. Cand. J. Phys 45 3849-3865 (1967).
    # hardness set to unity to remove dependence on that quantity
    block = 'sample sample_B_secondary_subdomain top_punch_B_secondary_subdomain
             sample_OD_secondary_subdomain'
  []
[]

[UserObjects]
  [closed_thermal_interface_bot_cup_bot_CFC]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = ccfiber_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = ccfiber_hardness
    boundary = bot_CFC_bottom
  []
  [closed_electrical_interface_bot_ram_bot_cup]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = ccfiber_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = ccfiber_hardness
    boundary = bot_CFC_bottom
  []
  [closed_thermal_interface_bottom_cc_sinter]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = ccfiber_thermal_conductivity
    secondary_conductivity = graphite_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = ccfiber_hardness
    secondary_hardness = graphite_hardness
    boundary = bot_spacer_bottom
  []
  [closed_electric_interface_bottom_cc_sinter]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = ccfiber_electrical_conductivity
    secondary_conductivity = graphite_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = ccfiber_hardness
    secondary_hardness = graphite_hardness
    boundary = bot_spacer_bottom
  []
  [closed_thermal_interface_bottom_sinter_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = graphite_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = bot_punch_bottom
  []
  [closed_electric_interface_bottom_sinter_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = graphite_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = bot_punch_bottom
  []
  [closed_thermal_interface_bottom_punch_powder]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = copper_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = copper_hardness
    boundary = sample_bottom
  []
  [closed_electric_interface_bottom_punch_powder]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = copper_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = copper_hardness
    boundary = sample_bottom
  []
  [closed_thermal_interface_powder_top_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = copper_thermal_conductivity
    secondary_conductivity = graphite_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = copper_hardness
    boundary = top_punch_bottom
  []
  [closed_electric_interface_powder_top_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = copper_electrical_conductivity
    secondary_conductivity = graphite_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = copper_hardness
    secondary_hardness = graphite_hardness
    boundary = top_punch_bottom
  []
  [closed_thermal_interface_top_punch_sinter]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = graphite_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = top_spacer_bottom
  []
  [closed_electric_interface_top_punch_sinter]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = graphite_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = top_spacer_bottom
  []
  [closed_thermal_interface_top_sinter_cc_spacer]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = ccfiber_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = ccfiber_hardness
    boundary = top_CFC_bottom
  []
  [closed_electric_interface_top_sinter_cc_spacer]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = ccfiber_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = ccfiber_hardness
    boundary = top_CFC_bottom
  []
  [closed_thermal_interface_top_cc_ram_spacer]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = graphite_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = top_cup_bottom
  []
  [closed_electric_interface_top_cc_ram_spacer]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = graphite_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = top_cup_bottom
  []
  [thermal_conduction_wall_low_punch]
    type = GapFluxModelConduction
    temperature = temperature
    boundary = bot_punch_right
    gap_conductivity = 5  # W/m-K ceramaterials, through thickness for graphite foil: https://www.ceramaterials.com/wp-content/uploads/2022/01/GRAPHITE_FOIL_TDS_CM_01_22.pdf
    # use_displaced_mesh = true
  []
  [electrical_conduction_wall_low_punch]
    type = GapFluxModelConduction
    temperature = potential
    boundary = bot_punch_right
    gap_conductivity = 6.67e-2  # S/m ceramaterials, through thickness for graphite foil: https://www.ceramaterials.com/wp-content/uploads/2022/01/GRAPHITE_FOIL_TDS_CM_01_22.pdf
    # use_displaced_mesh = true
  []
  [closed_thermal_interface_inside_die_low_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = graphite_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = bot_punch_right
  []
  [closed_electric_interface_inside_die_low_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = graphite_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = bot_punch_right
  []
  [thermal_conduction_wall_powder]
    type = GapFluxModelConduction
    temperature = temperature
    boundary = sample_right
    gap_conductivity = 5  # W/m-K ceramaterials, through thickness for graphite foil: https://www.ceramaterials.com/wp-content/uploads/2022/01/GRAPHITE_FOIL_TDS_CM_01_22.pdf
    # use_displaced_mesh = true
  []
  [electrical_conduction_wall_powder]
    type = GapFluxModelConduction
    temperature = potential
    boundary = sample_right
    gap_conductivity = 6.67e-2  # S/m ceramaterials, through thickness for graphite foil: https://www.ceramaterials.com/wp-content/uploads/2022/01/GRAPHITE_FOIL_TDS_CM_01_22.pdf
    # use_displaced_mesh = true
  []
  [closed_thermal_interface_inside_die_powder]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = copper_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = copper_hardness
    boundary = sample_right
  []
  [closed_electric_interface_inside_die_powder]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = copper_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = copper_hardness
    boundary = sample_right
  []
  [thermal_conduction_wall_top_punch]
    type = GapFluxModelConduction
    temperature = temperature
    boundary = top_punch_right
    gap_conductivity = 5  # W/m-K ceramaterials, through thickness for graphite foil: https://www.ceramaterials.com/wp-content/uploads/2022/01/GRAPHITE_FOIL_TDS_CM_01_22.pdf
    # use_displaced_mesh = true
  []
  [electrical_conduction_wall_top_punch]
    type = GapFluxModelConduction
    temperature = potential
    boundary = top_punch_right
    gap_conductivity = 6.67e-2  # S/m ceramaterials, through thickness for graphite foil: https://www.ceramaterials.com/wp-content/uploads/2022/01/GRAPHITE_FOIL_TDS_CM_01_22.pdf
    # use_displaced_mesh = true
  []
  [closed_thermal_interface_inside_die_top_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_thermal_conductivity
    secondary_conductivity = graphite_thermal_conductivity
    temperature = temperature
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = top_punch_right
  []
  [closed_electric_interface_inside_die_top_punch]
    type = GapFluxModelPressureDependentConduction
    primary_conductivity = graphite_electrical_conductivity
    secondary_conductivity = graphite_electrical_conductivity
    temperature = potential
    contact_pressure = interface_normal_lm
    primary_hardness = graphite_hardness
    secondary_hardness = graphite_hardness
    boundary = top_punch_right
  []
  # [gap_thermal_interface_bottom_sinter_die] Not adding surface to surface radiation
  #   type = GapFluxModelConduction
  #   temperature = temperature
  #   boundary = die_wall_bottom
  #   gap_conductivity = 0.0306  # W/m-K for argon at 600K: https://www.engineersedge.com/heat_transfer/thermal-conductivity-gases.htm
  #   # use_displaced_mesh = true
  # []
  # [gap_thermal_interface_top_sinter_die] not adding surface to surface radiation
  #   type = GapFluxModelConduction
  #   temperature = temperature
  #   boundary = die_wall_top
  #   gap_conductivity = 0.0306  # W/m-K for argon at 600K: https://www.engineersedge.com/heat_transfer/thermal-conductivity-gases.htm
  #   # use_displaced_mesh = true
  # []
[]

[Postprocessors]
  [applied_current]
    type = FunctionValuePostprocessor
    function = current_application
  []

  [pyrometer_point]
    type = PointValue
    variable = temperature
    point = '${fparse sample_radius + 0.004} ${y_pos_center_of_sample_interface} 0'
  []
[]

[Preconditioning]
  [smp]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  automatic_scaling = false
  line_search = 'none'

  # mortar contact solver options
  petsc_options = '-snes_converged_reason -pc_svd_monitor'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = ' lu       superlu_dist'
  snesmf_reuse_base = false

  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8
  nl_max_its = 20
  nl_forced_its = 2
  l_max_its = 50

  dtmax = 10
  dt = 6
  end_time = 1800
[]

[Outputs]
  color = false
  csv = true
  exodus = true
  perf_graph = true
[]
