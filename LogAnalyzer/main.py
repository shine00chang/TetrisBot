import tkinter as tk
import numpy as np
import time
from Settings import *


# Construct tk window
root = tk.Tk()
window = tk.Frame(root, width=400, height=800)
window.pack(expand=True, fill=tk.BOTH)

# Control panel construction. The panel is for controlling the program prior to loading.
control_panel = tk.Frame(window)

move_number_input = tk.Text(control_panel, height=5, width=20)
move_number_input.pack()

move_number_label = tk.Label(control_panel, text="move number:")
move_number_label.pack()


def beginLoad():
    # Read the desired move number from text box
    global move_number
    move_number = int(move_number_input.get("1.0", tk.END))
    move_number_label.config(text="move number: {}".format(move_number))

    # Instruct mainloop to start
    global should_start_load
    should_start_load = True


start_load_button = tk.Button(control_panel, text="Begin load", command=beginLoad)
start_load_button.pack()

control_panel.pack()

current_node_display_canvas = tk.Canvas(window, bg="tomato4", width=300, height=500)
current_node_display_canvas.pack(side=tk.LEFT)
node_display_list = tk.Canvas(window, bg="gold2", width=150, height=800)

v_scrollbar = tk.Scrollbar(window, orient='vertical')
v_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
v_scrollbar.config(command=node_display_list.yview)
node_display_list.config(yscrollcommand=v_scrollbar.set)

print("Begin Analysis of", LOG_FILE_PATH)
log_file = open(LOG_FILE_PATH, "r")
print("Opened file.")

move_number = -1
should_start_load = False


def getNextLogLine():
    raw_line = log_file.readline()
    return raw_line[raw_line.find("LOG-") + 4:-1]


def setCurrentNode(node_id):
    global current_node_id, node_changed
    current_node_id = node_id
    node_changed = True


def readNode():
    node_start = getNextLogLine()

    # create child node object
    node = Node()

    # read tags
    node_tags_str = getNextLogLine()
    node_tags = node_tags_str.split()[1:]

    # read id
    node_id_str = getNextLogLine()
    node.id = int(node_id_str[node_id_str.find("id") + 2:])

    # read grid
    grid = node.grid
    for y in range(0, 20):
        row_str = getNextLogLine()
        for x in range(0, 10):
            if row_str[x * 2] != '.':
                grid[y][x] = int(row_str[x * 2]) + 1
            else:
                grid[y][x] = 0
    return node


def constructNodeFrame(node_id):
    node = nodes[node_id]
    # Construct grid into tkinter view
    node.frame = tk.Frame(window, bg="red")

    node.canvas = tk.Canvas(node.frame, bg="black", height=OFFSETY + BLOCK_S * 20, width=OFFSETX + BLOCK_S * 10)
    node.canvas.pack(side=tk.LEFT)

    # Info & Traverse button
    frame = tk.Frame(node.frame)
    button = tk.Button(node.frame, text="Traverse", command=lambda node_id=node.id: setCurrentNode(node_id))
    button.pack()

    node.info_text = tk.Text(node.frame, width=30, height=10)
    node.info_text.insert(tk.END, "Children: {}\n".format(len(node.children)))
    node.info_text.insert(tk.END, "Id: {}".format(node.id))
    node.info_text.config(state=tk.DISABLED)
    node.info_text.pack()

    frame.pack(side=tk.RIGHT)

    grid = node.grid
    canvas = node.canvas
    for y in range(20):
        for x in range(10):
            if grid[y][x]:
                canvas.create_rectangle(x * BLOCK_S + OFFSETX, y * BLOCK_S + OFFSETY,
                                        x * BLOCK_S + BLOCK_S + OFFSETX, y * BLOCK_S + BLOCK_S + OFFSETY,
                                        fill=COLOR[grid[y][x]])
    node.frame_constructed = True


def constructPage(node_id):
    node = nodes[node_id]
    if not node.frame_constructed:
        constructNodeFrame(node_id)

    # Set current node display content to the current node's frame
    current_node_display_canvas.delete('all')
    # Back button
    back_button = tk.Button(window, text="Traverse to Parent", command=lambda node_id=node.parent_id: setCurrentNode(node_id))
    current_node_display_canvas.create_window(0, 0, anchor=tk.NW, window=back_button)
    current_node_display_canvas.create_window(0, 10, anchor=tk.NW, window=node.frame)

    # Set the children list to current node's children
    node_display_list.delete('all')
    for i in range(0, len(node.children)):
        child = nodes[node.children[i]]

        # If Frame has not yet been created.
        if not child.frame_constructed:
            constructNodeFrame(child.id)

        node_display_list.create_window(0, i * DISPLAY_HEIGHT, anchor=tk.NW,
                                        window=child.frame)
    node_display_list.config(scrollregion=node_display_list.bbox('all'))


# wait until inputs are given
print("Waiting for move number input...")
while not should_start_load:
    window.update()


# scroll to the correct move
print("Got move number input.. \nWorking on loading")
while True:
    line = getNextLogLine()
    line_arr = line.split()
    if line_arr[0] == "solver_start":
        current_move_number = int(line_arr[1])
        if move_number == current_move_number:
            break

# Read root node
nodes = {}
root_node = readNode()
nodes[0] = root_node

# Construct tree based on explore data
explore_sets = 0
while True:
    line = getNextLogLine()
    line_arr = line.split()
    if line_arr[0] == "solver_end":
        break

    if line_arr[0] == "children_of":
        explore_sets += 1

        # identify parent & length
        parent_id = int(line_arr[1])
        children_cnt = int(line_arr[2])

        for c in range(0, children_cnt):
            node = readNode()
            node.parent_id = parent_id

            # Add to database
            nodes[node.id] = node
            nodes[parent_id].children.append(node.id)


print("Finished reading, found {} explores".format(explore_sets))
node_display_list.pack(side=tk.RIGHT, expand=True, fill=tk.BOTH)

# main loop
current_node_id = 0
node_changed = True
while True:
    if node_changed:
        constructPage(current_node_id)
        node_changed = False
    window.update()
    time.sleep(0.1)
