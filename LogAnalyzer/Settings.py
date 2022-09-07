import numpy as np

BLOCK_S = 5
OFFSETX = 3
OFFSETY = 3
COLOR = ["wheat4", "red", "blue", "green", "yellow", "orange", "turquoise", "purple"]
LOG_FILE_PATH = "../Logs/log1.txt"
DISPLAY_HEIGHT = 160


class Node:
    def __init__(self):
        self.id = -1
        self.parent_id = -1
        self.children = []
        self.grid = np.zeros((20, 10), dtype=np.int8)
        self.frame = 0
        self.canvas = 0
        self.frame_constructed = False
        self.info_text = 0
        self.stats = {}

