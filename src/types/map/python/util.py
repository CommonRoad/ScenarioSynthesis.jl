from typing import Tuple
# import matplotlib.pyplot as plt
import numpy as np
# from commonroad.visualization.draw_dispatch_cr import draw_object
from commonroad.scenario.lanelet import Lanelet
from commonroad_dc.geometry.util import chaikins_corner_cutting, resample_polyline
from scipy.interpolate import interp1d
from shapely.geometry import LineString, Point


def resample_line(polyline: np.ndarray, n: int) -> np.ndarray:
    """
    Resamples polyline to be exactly n output vertices
    :param polyline: polyline
    :param n: number of output vertices
    :return: resampled line
    """
    if polyline.shape[0] == 1:
        return np.array(n * [polyline[0]])
    line = LineString(polyline)
    points = [line.interpolate(i / (n - 1), normalized=True) for i in range(n)]
    return np.array([(p.x, p.y) for p in points])


def smoothen_polyline(polyline: np.ndarray, resample_distance: float = 2, smoothing: int = 3) -> np.ndarray:
    """
    smooths resamples and smooths a polyline
    :param polyline:
    :param resample_distance:
    :param smoothing:
    :return:
    """
    return chaikins_corner_cutting(resample_polyline(polyline, resample_distance), smoothing)


def extrapolate_polyline(polyline: np.ndarray, offset: float = 10) -> np.ndarray:
    """
    Current ccosy (https://gitlab.lrz.de/cps/commonroad-curvilinear-coordinate-system/-/tree/development) creates
    wrong projection domain if polyline has large distance between waypoints --> resampling;
    initial and final points are not within projection domain -> extrapolation
    :param polyline: polyline to be used to create ccosy
    :param offset: offset of newly created polyline
    :return: extrapolated polyline
    """
    d1 = (polyline[0] - polyline[1]) / np.linalg.norm(polyline[0] - polyline[1])
    d2 = (polyline[-1] - polyline[-2]) / np.linalg.norm(polyline[-1] - polyline[-2])
    first = polyline[0] + d1 * offset
    first = first[np.newaxis]
    last = polyline[-1] + d2 * offset
    last = last[np.newaxis]

    return np.concatenate((first, polyline, last), axis=0)


def _split_polyline(polyline: np.ndarray, vertices: np.ndarray, min_norm=1) -> Tuple[
    np.ndarray, np.ndarray, np.ndarray]:
    """
    Splits a polyline into three segments: before, between and after the vertices projected onto the polyline
    :param polyline:
    :param vertices:
    :return:
    """
    line = LineString(polyline)
    proj = np.array([line.project(Point(v)) for v in vertices])
    min_proj = np.min(proj)
    max_proj = np.max(proj)
    inter_min = line.interpolate(min_proj)
    min_pt = np.array([inter_min.x, inter_min.y])[np.newaxis]
    inter_max = line.interpolate(max_proj)
    max_pt = np.array([inter_max.x, inter_max.y])[np.newaxis]

    pre = np.array([v for v in polyline if line.project(Point(v)) < min_proj])
    if pre.size == 0 or _polyline_norm(pre) < min_norm:
        pre = np.empty(0)
    else:
        pre = np.concatenate((pre, min_pt), axis=0)

    post = np.array([v for v in polyline if line.project(Point(v)) > max_proj])
    if post.size == 0 or _polyline_norm(post) < min_norm:
        post = np.empty(0)
    else:
        post = np.concatenate((max_pt, post), axis=0)

    mid = np.array([v for v in polyline if min_proj <= line.project(Point(v)) <= max_proj])
    if mid.size == 0:
        mid = np.concatenate((min_pt, max_pt), axis=0)
    else:
        mid = np.concatenate((min_pt, mid, max_pt), axis=0)
    return pre, mid, post


def _smooth_merge(long: np.ndarray, short: np.ndarray) -> np.ndarray:
    pre, mid, post = _split_polyline(long, short)
    if pre.size > 0:
        pre = prev_smooth(pre, short)
    if post.size > 0:
        post = np.flip(prev_smooth(np.flip(post, axis=0), np.flip(short, axis=0)), axis=0)
    if pre.size > 0 and post.size > 0:
        return np.concatenate((pre, short, post), axis=0)
    elif pre.size > 0:
        return np.concatenate((pre, short), axis=0)
    elif post.size > 0:
        return np.concatenate((short, post), axis=0)
    else:
        return mid


def _polyline_norm(vertices: np.ndarray) -> float:
    return float(np.sum(np.linalg.norm(np.diff(vertices, axis=0), axis=1)))


def merge_adjacent_lanelets(left_lanelet: Lanelet, right_lanelet: Lanelet) -> Lanelet:
    if _polyline_norm(right_lanelet.left_vertices) > _polyline_norm(left_lanelet.left_vertices):
        left = _smooth_merge(right_lanelet.left_vertices, left_lanelet.left_vertices)
    else:
        left = left_lanelet.left_vertices
    if _polyline_norm(left_lanelet.right_vertices) > _polyline_norm(right_lanelet.right_vertices):
        right = _smooth_merge(left_lanelet.right_vertices, right_lanelet.right_vertices)
    else:
        right = right_lanelet.right_vertices

    max_vertices = max(left.shape[0], right.shape[0])
    left = resample_line(left, max_vertices)
    right = resample_line(right, max_vertices)
    center = 0.5 * right + 0.5 * left

    # plt.figure()
    # plt.scatter(left[:, 0], left[:, 1])
    # plt.scatter(center[:, 0], center[:, 1])
    # plt.scatter(right[:, 0], right[:, 1])
    # plt.autoscale()
    # plt.axis("equal")
    # plt.show()

    lanelet = Lanelet(
        left, center, right,
        lanelet_id=int(str(left_lanelet.lanelet_id) + str(right_lanelet.lanelet_id)),
        predecessor=list(set(left_lanelet.predecessor) | set(right_lanelet.predecessor)),
        successor=list(set(left_lanelet.successor) | set(right_lanelet.successor)),
        adjacent_left=left_lanelet.adj_left,
        adjacent_left_same_direction=True,
        adjacent_right=right_lanelet.adj_right,
        adjacent_right_same_direction=True
    )
    lanelet.static_obstacles_on_lanelet = Lanelet._merge_static_obstacles_on_lanelet(
        left_lanelet.static_obstacles_on_lanelet, right_lanelet.static_obstacles_on_lanelet
    )
    lanelet.dynamic_obstacles_on_lanelet = Lanelet._merge_dynamic_obstacles_on_lanelet(
        left_lanelet.dynamic_obstacles_on_lanelet, right_lanelet.dynamic_obstacles_on_lanelet
    )
    return lanelet


def prev_smooth(prev: np.ndarray, next: np.ndarray,
                look_back_factor=0.2, resampling_distance=2.0) -> np.ndarray:
    look_back_dist = _polyline_norm(prev) * look_back_factor

    prev = resample_polyline(prev, resampling_distance)
    next = resample_polyline(next, resampling_distance)
    look_back = int(min(look_back_dist / resampling_distance, prev.shape[0]))
    v = np.concatenate((prev[-look_back - 2:-look_back], next[:2]))
    step = np.linspace(0, 1, num=v.shape[0])
    x = interp1d(step, v[:, 0], kind="linear")
    y = interp1d(step, v[:, 1], kind="linear")
    for i, s in enumerate(np.linspace(step[1], step[-2], num=look_back)):
        prev[-look_back + i, 0] = x(s)
        prev[-look_back + i, 1] = y(s)
    return prev