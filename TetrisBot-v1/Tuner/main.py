import random
import time
import tkinter as tk
import matplotlib.pyplot as plt

from Setting import *
from GeneticAlgorithm import GenerateDescendants
from SolverWrapper import SolverWrapper


# Construct window (board displays, control panel, settings)
window = tk.Tk()
side_frame = tk.Frame(window, bg="ivory2", height=800, width=200)
canvases = []
spotlight_canvas = tk.Canvas(side_frame, bg="black",
                             height=2 * (OFFSETY + BLOCK_S * 20), width=2 * (OFFSETX + BLOCK_S * 10))
spotlight_score = tk.StringVar()
console_text = tk.StringVar()
generation_label_text = tk.StringVar()
run_label_text = tk.StringVar()
scores = [0] * DISPLAYS
start = False
pause = False


def controller_on_start():
    global start
    start = True


def controller_on_pause():
    global pause
    pause = not pause


# construct window
window.geometry("1400x800")
title_label = tk.Label(side_frame, text="Tetris Genetic Algorithm Tuner:")
title_label.pack()
generation_label = tk.Label(side_frame, textvariable=generation_label_text)
generation_label.pack()
run_label = tk.Label(side_frame, textvariable=run_label_text)
run_label.pack()
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

# Construct plots
plt.autoscale()
fig, axs = plt.subplots(1, 3)
axs[0].set_title("Average Score per Generation")
axs[0].set_xlim(0, 2)
dt1, = axs[0].plot([0], [0])
axs[1].set_title("Best Score per Generation")
axs[1].set_xlim(0, 2)
dt2, = axs[1].plot([0], [0])
axs[2].set_title("Time per Action")
axs[2].set_xlim(0, 20)
axs[2].set_ylim(0, 1)
dt3, = axs[2].plot(np.arange(0, 20), np.zeros(20))
fig.show()


def change_datapoint(dt, ax, point):
    xdata = dt.get_xdata()
    ydata = dt.get_ydata()
    changed = False
    for i in range(len(xdata)):
        if xdata[i] == point[0]:
            ydata[i] = point[1]
            changed = True
            break
    if not changed:
        add_datapoint(dt, ax, point)
        return
    dt.set_ydata(ydata)
    ax.set_ylim(0, max(point[1], ax.get_ylim()[1]))
    fig.canvas.draw()


def add_datapoint(dt, ax, point):
    x, y = point
    dt.set_xdata(np.append(dt.get_xdata(), x))
    dt.set_ydata(np.append(dt.get_ydata(), y))
    ax.set_xlim(0, x)
    ax.set_ylim(0, max(y, ax.get_ylim()[1]))
    fig.canvas.draw()


def add_datapoint_loop(dt, ax, point):
    ydata = dt.get_ydata()
    ydata = ydata[1:]
    dt.set_ydata(np.append(ydata, point))
    fig.canvas.draw()


# Await start button
while not start:
    window.update()
    time.sleep(0.01)


# TODO: Load Settings From UI


agents = np.zeros(POPULATION_SIZE, dtype=Agent_t)
random_hold = random.randint(1, 7)
holds = np.full(POPULATION_SIZE, random_hold)
# Initialize weights (Random)
for i in range(POPULATION_SIZE):
    # Randomize Weights
    magnitude = 0
    weights = agents[i]['weights']
    for j in range(WEIGHTS):
        weights[j] = random.uniform(0, 1)
        magnitude += weights[j] * weights[j]
    magnitude = math.sqrt(magnitude)
    for j in range(WEIGHTS):
        weights[j] /= magnitude


generation = 1
while generation <= GENERATIONS:
    generation_label_text.set(str(generation))

    # canvas clearing canvas
    canvas_clear_counter = 0
    moves = 0
    # Fitness Test
    run = 1
    while run <= RUNS_PER_GENERATION:
        run_label_text.set(str(run))
        run_start = time.time()
        run_over = False
        piece_bag = [1, 2, 3, 4, 5, 6, 7]
        board = np.zeros((POPULATION_SIZE, 20, 10), dtype=np.int8)
        display = np.zeros((DISPLAYS, 20, 10), dtype=np.int8)
        spotlight_display = np.zeros((20, 10), dtype=np.int8)
        while not run_over and moves < MOVES_PER_RUN:
            run_over = True
            action_start = time.time()
            score_sum = 0
            # Check for pause
            if pause:
                console_text.set("PAUSED")
                while pause:
                    window.update()
                    time.sleep(0.01)
                console_text.set("")

            # Piece generation
            piece_i = random.randint(0, len(piece_bag) - 1)
            piece = piece_bag[piece_i]
            del piece_bag[piece_i]
            if not piece_bag:
                piece_bag = [1, 2, 3, 4, 5, 6, 7]

            # Run agents
            simulation_start = time.time()
            for i in range(POPULATION_SIZE):
                if not agents[i]['over']:
                    score_sum -= agents[i]['score']
                    run_over = False
                    # Run Model
                    over, held = SolverWrapper.run(agents[i], board[i], piece, holds[i])
                    if over:
                        agents[i]['over'] = True
                        continue

                    if held:
                        holds[i] = piece
                # update average score (for graph)
                score_sum += agents[i]['score']

            simulation_time = time.time() - simulation_start

            # Updating displays:
            draw_start = time.time()
            top_agent = 0
            for i in range(min(DISPLAYS, POPULATION_SIZE)):
                if agents[top_agent]['over'] or agents[i]['score'] > agents[top_agent]['score']:
                    top_agent = i
                if agents[i]['over']:
                    canvases[i].create_rectangle(0, 50, DISPLAY_WIDTH, 70, fill='red')
                    continue
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
                        spotlight_canvas.create_rectangle(2 * (x * BLOCK_S + OFFSETX), 2 * (y * BLOCK_S + OFFSETY),
                                                          2 * (x * BLOCK_S + BLOCK_S + OFFSETX),
                                                          2 * (y * BLOCK_S + BLOCK_S + OFFSETY),
                                                          fill=COLOR[board[top_agent][y][x]])
                        spotlight_display[y][x] = board[top_agent][y][x]
            spotlight_score.set(str(agents[top_agent]['score']))

            # Check processing time
            window.update()
            action_time = time.time() - action_start
            add_datapoint_loop(dt3, axs[2], action_time)
            change_datapoint(dt1, axs[0], (generation, score_sum / POPULATION_SIZE))
            print("Time consumed: draw: {:f}, simulate: {:f}, total: {:f}".format(time.time() - draw_start, simulation_time, action_time))

            if canvas_clear_counter == 10:
                print("canvases cleared")
                for canvas in canvases:
                    canvas.delete('all')
                display = np.zeros((DISPLAYS, 20, 10), dtype=np.int8)
                spotlight_canvas.delete('all')
                spotlight_display = np.zeros((20, 10), dtype=np.int8)
                canvas_clear_counter = 0
            canvas_clear_counter += 1
            moves += 1

        run += 1
        run_time = time.time() - run_start
        print("Time consumed per run: {:f}".format(run_time))

        for agent in agents:
            agent['over'] = False
        spotlight_canvas.delete('all')
        for canvas in canvases:
            canvas.delete('all')

    for agent in agents:
        agent['score'] /= RUNS_PER_GENERATION

    generation += 1
    agents = np.sort(agents, order='score')  # Ranked from lowest to highest
    agents = np.flip(agents)

    # Update Graphs
    # Best score of generation
    add_datapoint(dt2, axs[1], (generation, agents[0]['score']))
    print("Best Agent Score:{:d}, Weights:".format(agents[0]['score']))
    print(agents[0]['weights'])

    if generation > GENERATIONS:
        break
    # Generate next generation
    GenerateDescendants(agents)
    for agent in agents:
        agent['score'] = 0
    for score in scores:
        score.set(str(0))


# Print result
for i in range(POPULATION_SIZE):
    print("Rank #{:d}: Weights:".format(i))
    print(agents[i]['weights'])

# Prevent termination
while True:
    window.update()
    time.sleep(0.1)
