using ScenarioSynthesis

using Conda
using PyCall
using Pkg

ENV["PYTHON"] = "/home/florian/anaconda3/envs/pycall/"
# ENV["CONDA_JL_VERSION"] = "3.9"
ENV["CONDA_JL_HOME"] = "/home/florian/anaconda3/envs/pycall/"

Pkg.build("Conda")
Pkg.build("PyCall")

py"""
import sys
from pprint import pprint
from commonroad_dc.geometry.geometry import CurvilinearCoordinateSystem

pprint(sys.path)

#help("modules")
"""