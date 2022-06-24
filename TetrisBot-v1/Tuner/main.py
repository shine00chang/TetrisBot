import math
import random
import time

import numpy as np
import tkinter as tk
import Model
import Game

# Constants (not set through settings)
DISPLAYS = 120
DISPLAYS_PER_ROW = 20
DISPLAY_ROWS = math.floor(DISPLAYS / DISPLAYS_PER_ROW)
DISPLAY_HEIGHT = 130
DISPLAY_WIDTH = 60
BLOCK_S = 5
OFFSETX = 3
OFFSETY = 3
COLOR = ["black", "red", "blue", "green", "yellow", "orange", "turquoise", "purple"]

# Construct window (board displays, control panel, settings)
window = tk.Tk()
side_frame = tk.Frame(window, bg="ivory2", height=800, width=200)
canvases = []
spotlight_canvas = tk.Canvas(side_frame, bg="black",
                             height=2 * (OFFSETY + BLOCK_S * 20), width=2 * (OFFSETX + BLOCK_S * 10))
spotlight_score = tk.StringVar()
console_text = tk.StringVar()
scores = [0] * DISPLAYS
start = False
pause = False


def controller_on_start():
    global start
    start = True


def controller_on_pause():
    global pause
    pause = not pause


def construct_window():
    window.geometry("1400x800")
    title_label = tk.Label(side_frame, text="Tetris Genetic Algorithm Tuner:")
    title_label.pack()
    console_label = tk.Label(side_frame, textvariable=console_text)
    console_label.pack()
    start_button = tk.Button(side_frame, text="Start Population", command=controller_on_start)
    start_button.pack()
    pause_button = tk.Button(side_frame, text="Pause Training", command=controller_on_pause)
    pause_button.pack()
    spotlight_canvas.pack()
    spotlight_score_label = tk.Label(side_frame, textvariable=spotlight_score)
    spotlight_score_label.pack()
    side_frame.pack(side='left')

    for r in range(DISPLAY_ROWS):
        row = tk.Frame(window, height=DISPLAY_HEIGHT, width=DISPLAYS_PER_ROW * (10 * BLOCK_S + 10), bg="gold2")
        for i in range(DISPLAYS_PER_ROW):
            frame = tk.Frame(row, height=DISPLAY_HEIGHT, width=DISPLAY_WIDTH)
            canvas = tk.Canvas(frame, bg="black", height=OFFSETY + BLOCK_S * 20, width=OFFSETX + BLOCK_S * 10)
            scores[r * DISPLAYS_PER_ROW + i] = tk.StringVar()
            score = tk.Label(frame, textvariable=scores[r * DISPLAYS_PER_ROW + i])
            canvas.pack()
            score.pack()
            frame.pack(side='left')
            canvases.append(canvas)
        row.pack()


construct_window()

# Await start button
while not start:
    window.update()
    time.sleep(0.01)

# TODO: Load Settings
# Constants from settings
GENERATIONS = 10
HEURISTICS = 4
POPULATION_SIZE = 120

Agent_t = np.dtype([
    ('weights', np.int32, HEURISTICS),
    ('score', np.int32),
    ('over', bool)
])
agents = np.zeros(POPULATION_SIZE, dtype=Agent_t)
# TODO: Initialize weights
for agent in agents:
    for weight in agent['weights']:
        weight = random.randint(0, 100)
rigged = random.randint(0, POPULATION_SIZE-1)
agents[rigged]['weights'] = np.array([])


generation = 0
while generation <= GENERATIONS:
    generation_over = False
    board = np.zeros((POPULATION_SIZE, 20, 10), dtype=np.int8)
    display = np.zeros((DISPLAYS, 20, 10), dtype=np.int8)
    spotlight_display = np.zeros((20, 10), dtype=np.int8)

    # Fitness Test
    while not generation_over:
        start = time.time()
        # Check for pause
        if pause:
            console_text.set("PAUSED")
            while pause:
                window.update()
                time.sleep(0.01)
            console_text.set("")

        # Piece generation
        piece_i = random.randint(0, piece_bag.size()-1)
        piece = piece_bag[piece_i]
        del piece_bag[piece_i]
        if not piece_bag:
            piece_bag = [1, 2, 3, 4, 5, 6, 7]

        # Run agents
        for i in range(POPULATION_SIZE):
            # TODO: Run Model
            board[i] = Model.run(agents[i]['weights'], board[i], piece)
            # TODO: Apply game mechanics, update score
            Game.update(agents[i], board[i])

        # Updating displays:
        top_agent = 0
        for i in range(min(DISPLAYS, POPULATION_SIZE)):
            if agents[i]['score'] > agents[top_agent]['score']:
                top_agent = i
            for y in range(20):
                for x in range(10):
                    if display[i][y][x] != board[i][y][x]:
                        canvases[i].create_rectangle(x * BLOCK_S + OFFSETX, y * BLOCK_S + OFFSETY,
                                                     x * BLOCK_S + BLOCK_S + OFFSETX, y * BLOCK_S + BLOCK_S + OFFSETY,
                                                     fill=COLOR[board[i][y][x]])
                        display[i][y][x] = board[i][y][x]
            scores[i].set(str(agents[i]['score']))
        # Updating spotlight display:
        for y in range(20):
            for x in range(10):
                if spotlight_display[y][x] != board[top_agent][y][x]:
                    spotlight_canvas.create_rectangle(2*(x * BLOCK_S + OFFSETX), 2*(y * BLOCK_S + OFFSETY),
                                                      2*(x * BLOCK_S + BLOCK_S + OFFSETX), 2*(y * BLOCK_S + BLOCK_S + OFFSETY),
                                                      fill=COLOR[board[top_agent][y][x]])
                    spotlight_display[y][x] = board[top_agent][y][x]
        spotlight_score.set(str(agents[i]['score']))

        # Check processing time
        window.update()
        print(time.time() - start)
        time.sleep(0.1)

    ranked = np.sort(agents, order='score')  # Ranked from lowest to highest
    # TODO: Descendant Generation

# TODO: Print result
