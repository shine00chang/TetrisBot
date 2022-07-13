import ctypes

from Setting import HEIGHT_BONUS, SURVIVAL_BONUS

lib = ctypes.cdll.LoadLibrary('../Solver/libSolver.so')


class RetType(ctypes.Structure):
    _fields_ = [
        ("over", ctypes.c_bool),
        ("hold", ctypes.c_bool),
        ("clears", ctypes.c_int)
    ]


class SolverWrapper(object):
    @staticmethod
    def echo(message):
        lib.echo(message.encode())

    @staticmethod
    def run(agent, board, piece, hold):
        weights = agent['weights']
        # Flatten board & cast to c_int
        grid_raw = [ctypes.c_int(0)] * 200
        for y in range(20):
            for x in range(10):
                grid_raw[y * 10 + x] = ctypes.c_int(board[y][x])
        grid = (ctypes.c_int * 200)(*grid_raw)
        c_weights = (ctypes.c_double * weights.size)(*weights)
        ret_val = RetType()
        ret_val_ptr = ctypes.pointer(ret_val)
        lib.solve(grid, piece, int(hold), c_weights, ret_val_ptr)

        # Game Over
        if ret_val.over == 1:
            print("python: agent died")
            return True, False
        if ret_val.clears == 1:
            agent['score'] += 40
        if ret_val.clears == 2:
            agent['score'] += 100
        if ret_val.clears == 3:
            agent['score'] += 300
        if ret_val.clears == 4:
            agent['score'] += 1200

        height = 0
        for y in range(20):
            for x in range(10):
                board[y][x] = grid[y * 10 + x]
                if board[y][x] != 0:
                    height = 20 - y
        #agent['score'] += (20 - height) * HEIGHT_BONUS
        agent['score'] += SURVIVAL_BONUS
        return False, ret_val.hold
