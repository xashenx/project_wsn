#
#	AUTHOR:		FABRIZIO ZENI
#	STUDENT ID:	153465
#	FILE:		basic_sim_py
#	DESCRIPTION:	Script to execute the application through TOSSIM	
#	CASE:		A better link is added and we can see the update of the structure
#

from TOSSIM import *
import sys, StringIO
import random
import os

# The maximum number of lines to load from the noise file.
max_noise_lines = 100

# Creates the network topology from a file containing gain values for each
# pair of nodes. Each line of the file must have the following format:
#
# src_node dest_node link_gain
#
# For instance: 0 5 -90.71
# NOTE: The first node ID is 0.
def load_topology(r, topology_file):
    f = open(topology_file, "r")
    nodes_count = 0

    lines = f.readlines()
    for line in lines: 
        s = line.split() 
        if (len(s) > 0): 
            r.add(int(s[1]), int(s[2]), float(s[3].replace(',', '.')))
            if (int(s[1]) > nodes_count):
                nodes_count = int(s[1])
            if (int(s[2]) > nodes_count):
                nodes_count = int(s[2])
    f.close()

    nodes_count += 1
    print "Found", nodes_count, "nodes";
    return nodes_count


def load_noise(t, nodes_count):
    noiseFile = os.environ["TOSROOT"] + "/tos/lib/tossim/noise/meyer-heavy.txt"
    noise = open(noiseFile, "r")
    lines = noise.readlines()
    lines_cnt = 0
    for line in lines:
        lines_cnt += 1
        if (lines_cnt > max_noise_lines):
            break
        str = line.strip()
        if (str!= ""):
            val = int(str)
            for i in range(0, nodes_count):
                t.getNode(i).addNoiseTraceReading(val)

    for i in range(0, nodes_count):
        print "Creating noise model for", i;
        t.getNode(i).createNoiseModel()


# Configures each node to boot at a random time
def config_boot(t, nodes_count, sim_time):
    for i in range(0, nodes_count):
#        if (i!=7):
           bootTime = random.randint(1, 1000000)
           print "Node", i, "booting at", bootTime;
           t.getNode(i).bootAtTime(bootTime)
#        else:
 #          bootTime = int(sim_time * 10000000 * 0.75)
  #         print "Node", i, "booting at", bootTime;
   #        t.getNode(i).bootAtTime(bootTime)          

def remove_link(t, first_node, second_node):
    r = t.radio()
    print "Removing link from ",first_node," to ",second_node;
    r.remove(first_node,second_node)
    print "Removing link from ",second_node," to ",second_node;
    r.remove(second_node,first_node)

def add_link(t, first_node, second_node,value):
    r = t.radio()
    print "Adding link from ",first_node," to ",second_node;
    r.add(first_node,second_node,value)
    print "Adding link from ",second_node," to ",second_node;
    r.add(second_node,first_node,value)

def simulation_loop(t, sim_time, nodes_count):
    t.runNextEvent()
    startup_time = t.time()
    remove = 0
    add = 0
    another_add = 0
    while (t.time() < startup_time + sim_time * 10000000):
        t.runNextEvent()
#        if t.time() > sim_time * 10000000 * 0.30 and remove == 0:
 #          remove_link(t,2,0)
  #         remove_link(t,3,0)
   #        remove_link(t,4,2)
    #       remove = 1
     #   if t.time() > sim_time * 10000000 * 0.55 and add == 0:
#	   add_link(t,3,1,-55.44)
#	   add = 1
 #       if t.time() > sim_time * 10000000 * 0.60 and another_add == 0:
#	   add_link(t,2,6,-44.55)
#	   another_add = 1

# Runs a simulatio for sim_time (in ms) on the network defined in topology_file
def run_simulation(sim_time, topology_file):
    t = Tossim([])
    r = t.radio()

    nodes_count = load_topology(r, topology_file)
    load_noise(t, nodes_count)
    config_boot(t, nodes_count, sim_time)

# Add channels here. For instance:
    t.addChannel("routing", sys.stdout)
    t.addChannel("data", sys.stdout)

    simulation_loop(t, sim_time, nodes_count)



# Make a call to run_simulation here
run_simulation(575000, "generated.out")
