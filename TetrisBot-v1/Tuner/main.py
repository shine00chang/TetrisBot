import numpy as np
import tkinter as tk

window = tk.Tk()
title_text = tk.Label(text="Tetris Genetic Algorithm Tuner:")
title_text.pack()

# TODO: Await start button

# TODO: Load Settings

GENERATIONS = 0
HEURISTICS = 4
POPULATION_SIZE = 1

Agent_t = np.dtype([
    ('weights', np.int32, HEURISTICS),
    ('fitness', np.int32),
])
agents = np.zeros(GENERATIONS, dtype=Agent_t)

while GENERATIONS:
    generation_over = False
    board = np.zeros((POPULATION_SIZE, 20, 10))
    fitness = np.zeros(POPULATION_SIZE)
    while not generation_over:
        '''
        # TODO: Check for pause
        for agent in agents:
            board[i] = Model_Delegate.run(agent)
            # TODO: Check death, Update score
            Game.check_death(board[i])
        '''
        # TODO: Update Display
    # TODO: Rank population
    ranked = np.sort(agents, order='fitness')  # Ranked from lowest to highest
    # TODO: Descendant Generation

# TODO: Print result
