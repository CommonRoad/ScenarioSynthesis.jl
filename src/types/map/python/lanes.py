import numpy as np

from commonroad.scenario.lanelet import Lanelet, LaneletNetwork
from commonroad_dc.geometry.geometry import CurvilinearCoordinateSystem
from commonroad_dc.geometry.util import compute_pathlength_from_polyline
from copy import deepcopy
from fastcache import lru_cache
from typing import List, Union, Set, Dict, Iterable, Tuple, Optional
from src.types.map.python.scenario_parameters import ScenarioParamsBase
from src.types.map.python.util import resample_line, resample_polyline, prev_smooth, merge_adjacent_lanelets, extrapolate_polyline, smoothen_polyline


class SectionID:
    def __init__(self, id: int):
        self.id = id

    def __eq__(self, other: 'SectionID'):
        return True if self.id == other.id else None

    def __ne__(self, other: 'SectionID'):
        return not self.__eq__(other)

    def __str__(self):
        return str(self.id)

    def __hash__(self):
        return hash((self.id))


class LaneID:
    def __init__(self, section: SectionID, lat: int):
        self.section = section
        self.lat = lat

    @classmethod
    def create_from(cls, section: int, lat: int):
        return cls(SectionID(section), lat)

    @property
    def id(self):
        return f"{self.section}{self.lat}"

    def __eq__(self, other: 'LaneID'):
        if type(other) != LaneID:
            return False
        return True if self.section == other.section and self.lat == other.lat else None

    def __ne__(self, other: 'LaneID'):
        return not self.__eq__(other)

    def __le__(self, other):
        return True if self.section.id <= other.section.id and self.lat <= other.lat else False

    def __lt__(self, other):
        return True if self.section.id <= other.section.id and self.lat < other.lat else False

    def __ge__(self, other):
        return not self.__le__(other)

    def __gt__(self, other):
        return not self.__lt__(other)

    def is_adj(self, other: 'LaneID'):
        # Checks for adjacency of lanes.
        return type(self) == type(other) \
               and self.section == other.section \
               and (self.lat == other.lat + 1 or self.lat == other.lat - 1)

    def __str__(self):
        return "{},{}".format(self.section, self.lat)

    def __repr__(self):
        return str(self)

    def __hash__(self):
        return hash((self.section, self.lat))


class Lane:
    def __init__(self, lanelets: List[Lanelet], lane_id: Union[LaneID, List[LaneID]],
                 resampling_distance: float = 2.0, is_main_lane=False, create_csys=True):
        self.lane_id = lane_id
        self.lanelet_ids: List[int] = [lanelet.lanelet_id for lanelet in lanelets]
        self.successors: Set[int] = {successor for lanelet in lanelets for successor in lanelet.successor if
                                     successor not in self.lanelet_ids}
        self.predecessors: Set[int] = {predecessor for lanelet in lanelets for predecessor in lanelet.predecessor if
                                       predecessor not in self.lanelet_ids}

        self.is_main_lane = is_main_lane
        if type(lane_id) == list:
            self.merging_lane_ids = None
        else:
            self.merging_lane_ids: Set[LaneID] = {lane_id}  # contains intersecting lanes

        # merge all lanelets
        self.lanelet = lanelets[0]
        for i in range(1, len(lanelets)):
            # if the lanelets are adjacent, perform a manual merge
            if lanelets[i - 1].adj_right == lanelets[i].lanelet_id:
                self.lanelet = merge_adjacent_lanelets(self.lanelet, lanelets[i])
            elif lanelets[i - 1].adj_left == lanelets[i].lanelet_id:
                self.lanelet = merge_adjacent_lanelets(lanelets[i], self.lanelet)
            else:

                n_vertices = int(np.linalg.norm(
                    self.lanelet.center_vertices[-1] - self.lanelet.center_vertices[0]) / resampling_distance)
                self.lanelet._left_vertices = resample_line(
                    prev_smooth(self.lanelet.left_vertices, lanelets[i].left_vertices), n_vertices)
                self.lanelet._center_vertices = resample_line(
                    prev_smooth(self.lanelet.center_vertices, lanelets[i].center_vertices), n_vertices)
                self.lanelet._right_vertices = resample_line(
                    prev_smooth(self.lanelet.right_vertices, lanelets[i].right_vertices), n_vertices)
                self.lanelet = Lanelet.merge_lanelets(self.lanelet, lanelets[i])
                # copy adjacency from furthest lanelet to the entire chain,
                # not done by Lanelet.merge_lanelets()
                if lanelets[i].adj_left_same_direction is not None:
                    self.lanelet.adj_left_same_direction = lanelets[i].adj_left_same_direction
                if lanelets[i].adj_right_same_direction is not None:
                    self.lanelet.adj_right_same_direction = lanelets[i].adj_right_same_direction
                if lanelets[i].adj_left is not None:
                    self.lanelet.adj_left = lanelets[i].adj_left
                if lanelets[i].adj_right is not None:
                    self.lanelet.adj_right = lanelets[i].adj_right

        # create curvilinear system
        self.center_line = self.lanelet.center_vertices
        if resampling_distance > 0:
            self.center_line = resample_polyline(self.center_line, resampling_distance)

        self.curv_sys: Union[CurvilinearCoordinateSystem, None] = None
        self.s_range: Union[Tuple[float, float], None] = None
        if create_csys:
            ref_path = smoothen_polyline(extrapolate_polyline(self.center_line), resample_distance=resampling_distance)
            self.curv_sys: CurvilinearCoordinateSystem = CurvilinearCoordinateSystem(ref_path)

            # plt.figure(figsize=(10,10))
            # draw_object(self.lanelet)
            # plt.scatter(ref_path[:, 0], ref_path[:, 1], zorder=50)
            # plt.autoscale()
            # plt.tight_layout()
            # plt.axis("equal")
            # plt.show()

            min_i = next(i for i in range(self.center_line.shape[0])
                         if self.curv_sys.cartesian_point_inside_projection_domain(*self.center_line[i]))
            max_i = next(i for i in reversed(range(self.center_line.shape[0]))
                         if self.curv_sys.cartesian_point_inside_projection_domain(*self.center_line[i]))
            self.s_range = (self.curv_sys.convert_to_curvilinear_coords(*self.center_line[min_i])[0],
                            self.curv_sys.convert_to_curvilinear_coords(*self.center_line[max_i])[0])

            # # self.curv_sys.convert_to_curvilinear_coords(self.center_line[1][0],self.center_line[1][1])
            # domain = np.array(self.curv_sys.projection_domain())
            # plt.figure()
            # plt.scatter(domain[:, 0], domain[:, 1], color='r')
            # ref = np.array(self.curv_sys.reference_path())
            # plt.scatter(ref[:, 0], ref[:, 1], color='g')
            # plt.scatter(self.center_line[:, 0], self.center_line[:, 1], color="b", zorder=100)
            # plt.autoscale()
            # plt.draw()
            # plt.axis('equal')
            # plt.show()

            # except:
            #     import matplotlib.pyplot as plt
            #     plt.figure()
            #     plt.plot(self.center_line[:,0],self.center_line[:,1])
            #     plt.plot(self.lanelet.center_vertices[:,0], self.lanelet.center_vertices[:,1])
            #     plt.axis('equal')
            #     plt.show()
            #     print('sdf')
            # print('success')
            # long. bounds of lanelets
            # import matplotlib.pyplot as plt
            # # plt.figure()
            # # plt.plot(self.center_line[:,0],self.center_line[:,1])
            # # plt.plot(self.lanelet.center_vertices[:,0], self.lanelet.center_vertices[:,1])
            # # plt.show()
            # self.long_sections: Dict[int, float] = self._init_long_sections(lanelets, self.curv_sys)

    @staticmethod
    def _init_long_sections(lanelets: List[Lanelet], curv_sys: CurvilinearCoordinateSystem) -> Dict[int, float]:
        # Computes longitudinal bounds of lanelets.

        def get_s(lanelet):
            # print('coord')
            # print(lanelet.center_vertices)
            return curv_sys.convert_to_curvilinear_coords(lanelet.center_vertices[0, 0], lanelet.center_vertices[0, 1])[
                0]

        long_sections = {}
        for lanelet in lanelets:
            long_sections[lanelet.lanelet_id] = get_s(lanelet)

        return long_sections

    @classmethod
    def merge_lanes(cls, lane_1: 'Lane', lane_2: 'Lane', lane_id: Union[LaneID, List[LaneID]], resampling_distance=2.0):
        self = cls([lane_1.lanelet, lane_2.lanelet], lane_id=lane_id, resampling_distance=resampling_distance,
                   is_main_lane=lane_1.is_main_lane and lane_2.is_main_lane,
                   create_csys=lane_1.curv_sys is not None and lane_2.curv_sys is not None)
        self.lanelet_ids = lane_1.lanelet_ids + lane_2.lanelet_ids
        return self

    def contains_lanelet(self, lanelet_id: int):
        return True if lanelet_id in self.lanelet_ids else False

    def get_lanelet_with_lane_ids(self):
        lanelet_tmp = deepcopy(self.lanelet)
        lanelet_tmp._lanelet_id = self.lane_id
        lanelet_tmp._adj_left = self.merging_lane_ids
        lanelet_tmp._adj_right = self.merging_lane_ids
        id2lane_id = {}
        for lanelet_id in self.lanelet_ids:
            id2lane_id[lanelet_id] = self.lane_id
        return lanelet_tmp, id2lane_id

    def convert_to_curvilinear_coords(self, point: np.ndarray):
        return self.curv_sys.convert_to_curvilinear_coords(point[0], point[1])


class LaneSection:
    def __init__(self, sec_id: SectionID, lanelets: List[Lanelet], merging_lanes: List[Set[int]] = None,
                 resampling_distance=1.5):

        # :param sec_id:
        # :param lanelets: Lanelets ordered from left to right
        
        self.sec_id = sec_id
        self.lanes: List[Lane] = []
        for i, lanelet in enumerate(lanelets):
            self.lanes.append(
                Lane([lanelet], LaneID(self.sec_id, i), create_csys=True, resampling_distance=resampling_distance))

        self._predecessors = set()
        self._successors = set()

        self._verify_lanelet_order()
        self._update_pre_successors()
        self.merging_lanes: List[Set[int]] = merging_lanes if merging_lanes else []
        # self.connections = None

    def is_lane_change_possible(self, lane_id_1: LaneID, lane_id_2: LaneID):
        # Checks whether not lanes are merging -> no lane change possible.
        # TODO:lane change after merge should be possible.

        for merge in self.merging_lanes:
            if lane_id_1.lat in merge and lane_id_2.lat in merge:
                return False
        return True

    @classmethod
    def from_lanes(cls, id, lanes: List[Lane], merging_lanes: List[Set[int]]):
        self = cls(id, [])
        self.lanes = lanes
        self._update_pre_successors()
        self.merging_lanes = merging_lanes
        return self

    @property
    def merging_lanes(self) -> List[Set[int]]:
        return self._merging_lanes

    @merging_lanes.setter
    def merging_lanes(self, merging_lanes: List[Set[int]]):
        if len(merging_lanes) > 0:
            for i_lane, lane in enumerate(self.lanes):
                # collect lanes
                occupied_lanes_i = set()
                for merges in merging_lanes:
                    if i_lane in merges:
                        occupied_lanes_i = occupied_lanes_i.union(merges)

                # create_lane_ids
                occupied_lane_ids = set()
                for i_lane in occupied_lanes_i:
                    occupied_lane_ids.add(LaneID(self.sec_id, i_lane))

                lane.merging_lane_ids = occupied_lane_ids

        self._merging_lanes = merging_lanes

    @property
    def predecessors(self):
        return list(self._predecessors)

    @property
    def successors(self):
        return list(self._successors)

    def _update_pre_successors(self):
        for lane in self.lanes:
            self._predecessors |= set(lane.predecessors)
            self._successors |= set(lane.successors)
        lane_ids = {lane.lane_id for lane in self.lanes}
        self._predecessors -= lane_ids
        self._predecessors -= lane_ids

    @property
    def n_lanes(self):
        return len(self.lanes)

    def _verify_lanelet_order(self):
        if len(self.lanes) > 1:
            for i, lane in enumerate(self.lanes[:-2]):
                assert self.lanes[
                           i + 1].lanelet.lanelet_id == lane.lanelet.adj_left, "Lanelets not ordered from right to left."

    def add_lanelet(self, new_lanelet: Lanelet):
        if self.lanes[0].lanelet.lanelet_id == new_lanelet.adj_left:
            self.lanes.insert(0, new_lanelet)
            self._update_pre_successors()
            return
        else:
            for i, lanelet in enumerate(self.lanes):
                if lanelet.lanelet.lanelet_id == new_lanelet.adj_right:
                    self.lanes.insert(i + 1, new_lanelet)
                    self._update_pre_successors()
                    return

        raise (ValueError('Lanelet does not belong to this section.'))

    def get_lanelets(self):
        lanelets = []
        id2lane_id = dict()
        for lane in self.lanes:
            lanelet, id2lane_id_tmp = lane.get_lanelet_with_lane_ids()
            lanelets.append(lanelet)
            id2lane_id.update(id2lane_id_tmp)

        return lanelets, id2lane_id


class LaneSectionNetwork:
    def __init__(self, params):
        self._sections: Dict[SectionID, LaneSection] = {}
        self.lanelet2section_map: Dict[int, LaneSection] = None
        self.params = params

    @classmethod
    def create_from_lanelet_network(cls, lanelet_network, params: ScenarioParamsBase, combine_lane_merges=False):
        self = cls(params)
        self.lanelet2section_map = self._create_sections(lanelet_network)
        if combine_lane_merges is True:
            self._identify_merging_lanes(lanelet_network)
        return self

    @classmethod
    def create_from_section_list(cls, sections: List['LaneSection']):
        self = cls()
        self.sections = dict(zip([sec.sec_id for sec in sections], sections))
        self.lanelet2section_map = self._create_lane_mappings(self.sections)
        return self

    @lru_cache()
    def preceding_lanes(self, lane_id: LaneID) -> List[LaneID]:
        lane = self.get_lane(lane_id)
        if not lane:
            return []
        return [l.lane_id
                for lanelet_id in lane.predecessors
                for l in self.lanelet2section_map[lanelet_id].lanes
                if lanelet_id in l.lanelet_ids]

    @lru_cache()
    def succeeding_lanes(self, lane_id: LaneID) -> List[LaneID]:
        lane = self.get_lane(lane_id)
        if not lane:
            return []
        return [l.lane_id
                for lanelet_id in lane.successors
                for l in self.lanelet2section_map[lanelet_id].lanes
                if lanelet_id in l.lanelet_ids]

    @lru_cache()
    def outgoing_lanes(self, lane_id: LaneID) -> Set[LaneID]:
        return set(self.succeeding_lanes(lane_id)) \
               | {self.adj_left_lane(lane_id), self.adj_right_lane(lane_id)} \
               - {None}

    def _adj_lane(self, lane_id: LaneID, left=True) -> Optional[LaneID]:
        if not lane_id.section in self.sections:
            return None
        section = self.sections[lane_id.section]
        lane_idx = next((i for i, l in enumerate(section.lanes) if l.lane_id == lane_id), None)
        if lane_idx is None:
            return None
        adj_idx = lane_idx + 1 if left else lane_idx - 1
        return section.lanes[adj_idx].lane_id if 0 <= adj_idx < len(section.lanes) else None

    @lru_cache()
    def adj_left_lane(self, lane_id: LaneID) -> Optional[LaneID]:
        return self._adj_lane(lane_id, left=True)

    @lru_cache()
    def adj_right_lane(self, lane_id: LaneID) -> Optional[LaneID]:
        return self._adj_lane(lane_id, left=False)

    def get_lanelet_ids(self, lane_id: LaneID) -> List[int]:
        # :returns original lanelet_id from lane_id
        lane = self.get_lane(lane_id)
        if not lane:
            return []
        else:
            return list(lane.lanelet_ids)

    def lanelet_id2lane_id(self, lanelet_id: int) -> List[LaneID]:
        return [lane.lane_id for section in self.sections.values() for lane in section.lanes if
                lanelet_id in lane.lanelet_ids]

    @lru_cache()
    def get_lane(self, lane_id: LaneID) -> Union[Lane, None]:
        # assert type(lane_id) == LaneID, 'type has to be LaneID, but is of type{}'.format(type(lane_id))
        if lane_id.lat < 0:
            return None

        try:
            return self.sections[lane_id.section].lanes[lane_id.lat]
        except (KeyError, IndexError):
            return None
        except IndexError:
            return None

    def merge_sections(self, secs_pred: List[LaneSection], sec_succ: LaneSection):
        # Merge successor section sec_succ and multiple preceding sectiongs which merge into one or multiple lanes
        # from sec_succ.
        new_lanes = []
        merging_lanes = []
        lane_counter = 0
        if type(secs_pred) == set:
            secs_pred = list(secs_pred)
            secs_pred.sort(key=lambda x: x.sec_id.id)

        for lane_suc in sec_succ.lanes:
            merging_lanes_tmp = set()
            # collect all lanes from all preceding sections which merge into lane_suc
            for sec_pred in secs_pred:
                for lane_pred in sec_pred.lanes:
                    if set(lane_suc.lanelet_ids) & set(lane_pred.lanelet.successor):
                        merging_lanes_tmp.add(lane_counter)
                        new_lanes.append(Lane.merge_lanes(lane_pred, lane_suc, LaneID(sec_succ.sec_id, lane_counter),
                                                          resampling_distance=self.params.reference_resampling))
                        lane_counter += 1

            if len(merging_lanes_tmp) == 0:
                # lane does not contain merges
                lane_suc.lane_id.lat = lane_counter
                new_lanes.append(lane_suc)
                lane_counter += 1

            merging_lanes.append(merging_lanes_tmp)

        # map old ID to new ID and delete preceding section
        del self._sections[sec_succ.sec_id]
        for sec_pred in secs_pred:
            del self._sections[sec_pred.sec_id]
            sec_pred.sec_id.id = sec_succ.sec_id.id

        self._sections.update({sec_succ.sec_id: LaneSection.from_lanes(sec_succ.sec_id, new_lanes, merging_lanes)})

    @property
    def sections(self) -> Dict[SectionID, LaneSection]:
        return self._sections

    @sections.setter
    def sections(self, sections: List[LaneSection]):
        self._sections = {}
        if isinstance(sections, dict):
            self._sections = sections
        else:
            for section in sections:
                self._sections[section.sec_id] = section

    def generate_lane_section_id(self) -> SectionID:
        # Generates a unique ID which is not assigned to any lane_section.
        
        if len(self._sections) > 0:
            return SectionID(max([id.id for id in self._sections]) + 1)
        else:
            return SectionID(0)

    def _create_sections(self, lanelet_network: LaneletNetwork) -> Dict[int, LaneSection]:
        # sections = {}
        lanelet2section_id = {}
        # sort by lanelet id (important, since lane_ids will be named consistently)
        lanelet_ids, lanelets = zip(*lanelet_network._lanelets.items())
        lanelet_ids, lanelets = zip(*sorted(zip(lanelet_ids, lanelets)))

        # going from right to left lanelet
        for lanelet_id, lanelet in zip(lanelet_ids, lanelets):
            if lanelet_id in lanelet2section_id or lanelet.adj_right is not None:
                # ensures starting at right-most lanelet
                continue

            # create new section
            sec_id = self.generate_lane_section_id()
            lanelets_tmp = [lanelet]
            next_lanelet: Lanelet = lanelet

            while next_lanelet.adj_left is not None and next_lanelet.adj_left_same_direction:
                next_lanelet = lanelet_network.find_lanelet_by_id(next_lanelet.adj_left)
                lanelets_tmp.append(next_lanelet)

            self._sections[sec_id] = LaneSection(sec_id, lanelets_tmp)
            for lanelet in lanelets_tmp:
                lanelet2section_id[lanelet.lanelet_id] = self.sections[sec_id]
        return lanelet2section_id

    def _create_lane_mappings(self, lane_sections: Dict[SectionID, 'LaneSection']):
        lanelet2section_map = dict()
        for _, lane_sec in lane_sections.items():
            for lane in lane_sec.lanes:
                for lanelet_id in lane.lanelet_ids:
                    lanelet2section_map[lanelet_id] = lane_sec

        return lanelet2section_map

    def _identify_merging_lanes(self, lanelet_network):
        # Identifies lane merges by checking for multiple predecessors of each lanelet.
        # Merging lanes are concatenated with their successor.
        assert len(self.sections) > 0 and self.lanelet2section_map is not None
        merged_lanelets: List[int] = []
        l = lanelet_network.lanelets
        l.sort(key=lambda x: x.lanelet_id)

        for lanelet in l:
            if lanelet.lanelet_id in merged_lanelets:
                continue
            # merge_map:Dict[List[Lanelet],Lanelet] = {}
            # lane_merges: Dict[int,List[int]] = defaultdict(list)  # {prev_section_id:[successor_id:[list of predecessors]]}
            if len(lanelet.predecessor) > 1:
                # predecessors are merging
                section_suc = self.lanelet2section_map[lanelet.lanelet_id]
                sections_pre: Set[LaneSection] = set()
                for lane in section_suc.lanes:
                    merged_lanelets.extend(lane.lanelet_ids)
                    if len(lane.lanelet.predecessor) > 1:
                        lane.lanelet.predecessor.sort()
                        for pre in lane.lanelet.predecessor:
                            sections_pre.add(self.lanelet2section_map[pre])

                self.merge_sections(sections_pre, section_suc)

        self.lanelet2section_map = self._create_lane_mappings(self.sections)

    def crop_border_sections(self):
        for sec_id, section in self.sections.items():
            crop_id = None
            if len(section.predecessors) == 0:
                for lane in section.lanes:
                    # if crop_id is None:
                    distances = compute_pathlength_from_polyline(lane.center_line)
                    crop_id = np.argmax(distances > 5) + 1

                    lane.center_line = lane.center_line[crop_id:, :]

        for sec_id, section in self.sections.items():
            crop_id = None
            if len(section.successors) == 0:
                for lane in section.lanes:
                    # if crop_id is None:
                    distances = compute_pathlength_from_polyline(lane.center_line)
                    crop_id = len(distances) \
                              - np.argmax(distances[::-1] < distances[-1] - 10)

                    lane.center_line = lane.center_line[:crop_id, :]

    """
    def plot(self, draw_params=None):
        draw_object(self.lanelets, draw_params=draw_params)
        # draw_intersection_intervals()
    """

    @property
    def lanelet_network(self):
        def replace_id(lanelet, property: Union[List[str], str]):
            value = lanelet.__getattribute__(property)
            if isinstance(value, Iterable):
                value = [id2lane_id[id] for id in value]
            else:
                value = id2lane_id[value]

            lanelet.__setattr__(property, value)

        if not hasattr(self, '_lanelet_network'):
            lanelets = []
            id2lane_id = dict()
            for _, section in self.sections.items():
                lanelets_tmp, id2lane_id_tmp = section.get_lanelets()
                lanelets.extend(lanelets_tmp)
                id2lane_id.update(id2lane_id_tmp)

            # replace lanelet_ids with laneIDs
            properties = ['_successor', '_predecessor']
            for l in lanelets:
                for p in properties:
                    replace_id(l, p)

            self._lanelet_network = LaneletNetwork.create_from_lanelet_list(lanelets)
        return self._lanelet_network

    @property
    def lanelets(self):
        # Corresponds to lanelet_network.lanelets
        return self.lanelet_network.lanelets

    @property
    def _lanelets(self) -> Dict[LaneID, Lane]:
        # Corresponds to lanelet_network._lanelets
        return self.lanelet_network._lanelets

    """
    def draw(self, ax=None):
        colors = cycle(mcolors.TABLEAU_COLORS)
        draw_object(self.lanelets, ax=ax)
        # draw Lane IDs
        for section in self.sections.values():
            for lane in section.lanes:
                pos = np.median(lane.center_line, axis=0)
                pos += np.array([-5, 0])
                plt.text(*pos, f"$({lane.lane_id})$", zorder=50, fontsize="x-small")
                # color lanes
                # plt.fill(*lane.lanelet.convert_to_polygon().shapely_object.exterior.xy,
                #          zorder=40, color=color, alpha=.25)
    """
