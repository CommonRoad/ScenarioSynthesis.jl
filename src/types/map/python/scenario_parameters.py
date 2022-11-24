import numpy as np


class ScenarioParamsBase: # TODO clean up
    # paths = [(47240,47246)]  # DEU_Gar-1_1_T-1
    ### paths = [(34782, 34782), (34784, 34784)]  # DEU_Muc-4_1_T-1/ # TODO uncomment if necessary
    # paths = [(718,723),(708,723)] # ZAM_merge
    # paths = [(50201,50197),(50205,50197)] # DEU_Ffb-2_1
    # paths = [(34784,34784)] # DEU_Muc-2_1_T-1
    # paths = [(50201, 50213), (50195, 50209), (50205, 50217)]  # DEU_Ffb-2_1 #Linkasabbieger
    # paths = [(50213, 50213), (50209, 50209), (50205, 50217)]  # DEU_Ffb-2_1 #Linkasabbieger
    # paths = [(49578,49568),(49564,49568),(49578,49572)] # DEU_Ffb-1_1
    # paths = [(49578,49568),(49564,49568)] # DEU_Ffb-1_1 merging intersection
    # paths = [(49578,49592),# N->E
    #          (49574,49590), # E->S
    #          (49570,49588)] # S->W # DEU_Ffb-1_1 left-turn
    # paths = [(8,5),(4,7)] # ZAM_Intersect-1_1 ,(34,37)

    ### general ###
    verbose = False
    # intersection_mode = True # ignores isOnLane's lonfgitudinal constraints

    ### plotting ###
    d_steps = 2

    ### scenario options ###############################
    t_f = 45
    dt = 0.25
    dt_reach = 0.25

    MIN_MODE_DURATION = 0.5
    MIN_LC_DURATION = 1.5
    CONT_LANE_CHANGE = True

    ### SPECIFICATION GENERATION
    propagation = [['LC'] * 2]
    veh_per_lane = 3
    # abs_max. number of vehicles changing their section in succeeding modes
    max_long_section_changes = 0
    # abs_min. number of lane changes all vehicle combined have to perform during complete sequence
    filter_min_lane_changes = 0
    # abs_min. number of section changes each vehicle has to perform during complete sequence
    filter_min_long_section_changes = 0
    # abs_min. number of vehicles with intersection states in specification at least once
    filter_intersection_state_occurence = {'isPastIntersection': 0, 'isOnIntersection': 0}

    ## vehicle dynamics
    length = 5
    width = 2
    a_min = -7
    a_max = 3  # 9.81
    a_max_total = 7  # 9.81 #9.81
    # vehicle max lateral velocity (m/s)
    v_max = 100 / 3.6
    lat_v_max = 5.0

    # longitudinal_planning
    min_dist_long = 3
    nx = 3
    # j_min = -12
    # j_max = 12
    j_min = -0.15e4
    j_max = 0.15e3
    v_min = 0
    v_max = 20
    s_bounds = [0, 150]  # width of initial s interval

    long_lane_overlap = 30  # longitudinal overlap to preceeding lane for lower bound of long. constraint
    intersection_overlap = 10

    ### mixed integer optimization ###############################

    gurobi_params = {
        'time_limit': 15,  # s
        'heuristics': 0.5,  # found by model.tune()
        'MIPFocus': 2,  # 1:good solutions, 2: proving best bound, 3. improving lower bound
        # 'SolutionLimit':20
    }
    M_s = 300
    M_ds = 50

    # lateral planning
    lat_j_max = 1e4
    sys_lat_nx = 3
    sys_lat_nu = 1
    Q = np.diag([5, 1, 1])
    R = np.diag([0.5])

    ### lane options ##############################################
    reference_resampling = 1.0  # resampling center line of lanes
    lane_width = 2.0

    ### Criticality Critertion ####################################
    t0_criticality = 1.75

    #### other ##########################################
    LANE_CHANGE_ID = 100  # automatically generated lane change modes start with

    #### derived values ##########################################
