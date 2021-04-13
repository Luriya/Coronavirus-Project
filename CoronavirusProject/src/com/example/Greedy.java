package com.example;

/**
 * Greedy contains a set of methods that attempt to solve a number of different
 * problems using a greedy approach. The greedy approach looks at all possible
 * steps that can be taken from a given position and selects the one that gives
 * the best current improvement. It can also be thought of as a hill climbing
 * approach where the goal is to get to the highest point over the shortest
 * distance. It can be useful to solve a lot of problems but gets stuck in
 * situations where in order to make a longer term improvement, it must first
 * make some short term losses. With respect to hill climbing, you can think of
 * it refusing to move from a false summit which it considers to be the best
 * solution, even if there is a higher summit further away but which requires
 * you to go back down first.
 *
 * @author David Cairns
 * @date 23/11/13
 */
public class Greedy {

    /**
     * This method attempts to solve the simple pattern matching problem using
     * the greedy approach.
     *
     * @param target The target pattern that it is trying to reproduce
     * @return The proposed solution pattern
     */
    public Pattern greedyPattern(Pattern target) {
        // Find out the dimensions of the target pattern
        int length = target.getLength();
        int height = target.getHeight();

        // Start with a random pattern

        // What is the difference between this and the target
//		float best = s.scoreNetLogoSolution(solution);
//	
//		float 	score;	// Current score of a solution
//		int 	g = 0;	// Count of the number of attempts
//		
//		// Now try changing 1 bit at a time
//		for (int x=0; x<length; x++)
//			for (int y=0; y<height; y++)
//			{
//				// If we have a perfect fit, return the solution
//				if (best == 0) return solution;
//				
//				// Get the bit value that we will change
//				float current = solution.get(x, y);
//				
//				// Flip its value and set it in our solution
//				if (current == 0)
//					solution.set(x, y, 1.0f);
//				else
//					solution.set(x, y, 0.0f);
//				
//				// Find out the new score
//				score = s.scoreSolution(solution,target);
//				
//				// If this did not improve matters, undo it and 
//				// move to the next location
//				if (score > best)
//				{
//					solution.set(x, y, current);
//				}
//				else
//				{
//					best = score;	// Keep this change
//				}
//				
//				g++;	// Keep a count of evaluations
//				
//				// Every 100 generations, print out the current score
//				if (g % 100 == 0)
//				{
//					String debug = String.format("%d\t%.2f",g,best);
//					System.out.println(debug);
//				}
//			}

        // Return the solution we built
        return new Pattern(length, height);
    }

    /**
     * Swaps around the values at locations 'p1' and 'p2' in 'route'.
     */
    public void swap(int p1, int p2, int[] route) {
        int temp = route[p1];
        route[p1] = route[p2];
        route[p2] = temp;
    }

}
