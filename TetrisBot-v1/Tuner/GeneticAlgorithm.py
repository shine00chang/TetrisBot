import random

from Setting import *


def crossOver(p1, p2):
    weights = [0] * WEIGHTS
    magnitude = 0
    for i in range(WEIGHTS):
        weights[i] = p1['weights'][i] * p1['score'] + p2['weights'][i] * p2['score']
        magnitude += weights[i] * weights[i]
    magnitude = math.sqrt(magnitude)
    for i in range(WEIGHTS):
        weights[i] /= magnitude
    return weights


def GenerateDescendants(agents):
    descendants = np.zeros(math.floor(POPULATION_SIZE * 0.5), dtype=Agent_t)
    for i in range(descendants.size):
        selected_agents = np.random.randint(0, POPULATION_SIZE, (math.floor(CROSSOVER_EXPLORATION_FACTOR * POPULATION_SIZE)))
        selected_agents = np.sort(selected_agents)
        descendants[i]['weights'] = crossOver(agents[selected_agents[0]], agents[selected_agents[1]])

        if random.random() < MUTATION_RATE:
            j = random.randint(0, WEIGHTS - 1)
            weights = descendants[i]['weights']
            weights[j] += max(0.0, random.uniform(-MUTATION_RANGE, MUTATION_RANGE))
            magnitude = 0
            for k in range(WEIGHTS):
                magnitude += weights[k] * weights[k]
            magnitude = math.sqrt(magnitude)
            for k in range(WEIGHTS):
                weights[k] /= magnitude

    for i in range(descendants.size):
        agents[POPULATION_SIZE - i - 1] = descendants[i]

