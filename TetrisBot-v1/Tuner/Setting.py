import math
import numpy as np

DISPLAYS = 120
DISPLAYS_PER_ROW = 20
DISPLAY_ROWS = math.floor(DISPLAYS / DISPLAYS_PER_ROW)
DISPLAY_HEIGHT = 130
DISPLAY_WIDTH = 60
BLOCK_S = 5
OFFSETX = 3
OFFSETY = 3
COLOR = ["black", "red", "blue", "green", "yellow", "orange", "turquoise", "purple"]

# -- Basic heuristic
# WEIGHTS = 4
# SIMPLE = True
# -- Tetris-based, complex heuristic
WEIGHTS = 14
SIMPLE = False


GENERATIONS = 20
POPULATION_SIZE = 120
RUNS_PER_GENERATION = 2
MOVES_PER_RUN = 400

SURVIVAL_BONUS = 1

MUTATION_RATE = 0.2
MUTATION_RANGE = 0.4
CROSSOVER_EXPLORATION_FACTOR = 0.03

Agent_t = np.dtype([
    ('weights', np.double, WEIGHTS),
    ('score', np.int32),
    ('over', bool)
])
