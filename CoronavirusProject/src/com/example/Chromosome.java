package com.example;

import java.util.ArrayList;

/**
 * This class is used to store the 'genetic material' that encodes the solution
 * to a problem. The meaning of the genes is relative to the problem. In some
 * cases they may encode bit values in a pattern, in other cases they are the
 * indexes of locations to visit on a map. The GA does not generally need to
 * know what they mean in order to operate correctly although there can be
 * different constraints on what the valid ranges of the genes can be.
 *
 * @author David Cairns
 * @date 21/11/13
 */
public class Chromosome {

    private Pattern genes;            // The set of values comprising this solution
    private float fitness = 0.0f;    // The fitness score associates with the 'genes'
    private float infections;
    private float totalInfections;
    private float deaths;
    private float totalDeaths;
    private float iCost;
    private float mCost;

    /**
     * Creates a random initial solution based on a grid of values 'xdim' by 'ydim'
     *
     * @param xdim Length of grid
     * @param ydim Height of grid
     */
    public Chromosome(int xdim, int ydim) {
        genes = new Pattern(xdim, ydim);
    }

    /**
     * Creates a new Chromsome object using 'template' to
     * set the required value (dimensions or problem reference).
     *
     * @param template The template to use, gene values are not copied
     */
    public Chromosome(Chromosome template) {
        genes = new Pattern(template.genes);
        fitness = 0.0f;
    }

    public float getInfections() {
        return infections;
    }

    public void setInfections(float infections) {
        this.infections = infections;
    }

    public float getTotalInfections() {
        return totalInfections;
    }

    public void setTotalInfections(float totalInfections) {
        this.totalInfections = totalInfections;
    }

    public float getDeaths() {
        return deaths;
    }

    public void setDeaths(float deaths) {
        this.deaths = deaths;
    }

    public float getTotalDeaths() {
        return totalDeaths;
    }

    public void setTotalDeaths(float totalDeaths) {
        this.totalDeaths = totalDeaths;
    }

    // Infection cost
    public float getICost() {
        return iCost;
    }

    public void setICost(float iCost) {
        this.iCost = iCost;
    }

    // Method cost
    public float getMCost() {
        return mCost;
    }

    public void setMCost(float mCost) {
        this.mCost = mCost;
    }

    /**
     * Return a duplicate of this Chromosome that can be changed without
     * affecting this one.
     */
    public Chromosome clone() {
        Chromosome c = new Chromosome(this);

        c.fitness = this.fitness;
        c.genes = this.genes.clone();

        return c;
    }


    /**
     * Randomly flip bits in the genes with a chance of flipping
     * a bit equal to 'probability'.
     *
     * @param probability The chance of flipping a bit
     */
    public void mutateBoolean(float probability) {
        for (int g = 0; g < genes.getSize(); g++) {
            if (Math.random() < probability) {
                // Flip the value
                if (genes.get(g) == 0)
                    genes.set(g, 1.0f);
                else
                    genes.set(g, 0.0f);
            }
        }
    }

    /**
     * Randomly flip bits in the genes with a chance of flipping
     * a bit equal to 'probability'.
     *
     * @param probability The chance of flipping a bit
     */
    public void mutateReal(float probability) {
        for (int g = 0; g < genes.getSize(); g++) {
            if (Math.random() < probability) {
                genes.set(g, (float) (Math.random()));
            }
        }
    }

    /**
     * Swap locations encoded in the genes with the given 'probability' of
     * doing a swap.
     *
     * @param probability The chance of swapping a particular gene with another
     */
    public void mutateRoute(float probability) {
        int size = genes.getSize();

        for (int g = 0; g < size; g++) {
            if (Math.random() < probability / 2) {
                genes.swap(g, (int) (Math.random() * size));
            }
        }
    }

    /**
     * Returns a route as an ArrayList (internally it is stored as a float array)
     *
     * @return The route as an ArrayList of Integer
     */
    public ArrayList<Integer> getRoutes() {
        ArrayList<Integer> rt = new ArrayList<>();

        for (float f : genes.getGenes())
            rt.add((int) f);

        return rt;
    }

    // The following provide accessor methods for the attributes of Chromosome.

    public float getFitness() {
        return fitness;
    }

    public void setFitness(float f) {
        fitness = f;
    }

    public Pattern getPattern() {
        return genes;
    }

    public float getGene(int g) {
        return genes.get(g);
    }

    public void setGene(int g, float value) {
        genes.set(g, value);
    }

    public int numGenes() {
        return genes.getSize();
    }

    public String toString() {
        return genes.toString();
    }

}

