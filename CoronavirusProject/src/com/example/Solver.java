package com.example;

import org.junit.Test;

import java.io.File;
import java.io.FileNotFoundException;


/**
 * Solver sets up our different problems and tries to solve them in different ways.
 */

public class Solver {

    //H:\4th Year\CSCU9Z7
    //C:\Users\luriy\Documents\University\4th Year\Spring\CSCU9Z7\
    public static final String projectPath = "[File Location]"; // Needs to be changed to suit system or location
    ModelSimulation ms = null;
    File f;
    // The following is used to keep a track of how many times we call the
    // objective function. It is normally proportional to the amount of work
    // involved in finding a solution to a problem
    private int evaluations = 0;

    public Solver(String folder, String model) {
        ms = new ModelSimulation(folder, model);
    }

    public static void main(String[] args) throws FileNotFoundException {
        Solver s = new Solver(projectPath, "covid-model.nlogo");
//        s.parameterSweep(6);
        //System.out.format("Time elapsed for run: %f%n", ((System.nanoTime() - startTime) / 1000000000));
        //float startTime = System.nanoTime();
        s.optimiseNetLogoModel(12); // Optimise a NetLogo model with 12 parameters
        //System.out.format("Time elapsed for run: %f%n", ((System.nanoTime() - startTime) / 1000000000));
    }

    @Test
    public void optimiseNetLogoModel(int numParameters) throws FileNotFoundException {

        // Now try to get the GA to guess the pattern
        evaluations = 0;
        GA ga = new GA();
        // evolveNetLogo(Solver s, int parameters, int popsize, int generations, float mutationRate, int tournamentSize)
        Pattern solution = ga.evolveNetLogo(this, numParameters, 30, 20, 0.05f, 4);
        System.out.println("GA Evaluations " + evaluations + "\n");
        System.out.println(solution);

    }

    @Test
    public void parameterSweep(int numParameters) throws FileNotFoundException {

        // Now try to get the GA to guess the pattern
        evaluations = 0;
        GA ga = new GA();
        // evolveNetLogo(Solver s, int parameters, int popsize, int generations, float mutationRate, int tournamentSize)
        Pattern solution = ga.parameterSweep(this, numParameters, 64);
        System.out.println("GA Evaluations " + evaluations + "\n");
        System.out.println(solution);

    }

    // We score our solutions via the following method so that we can keep
    // a count of how often they are called using the 'evaluations' counter.
    // This gives a reasonable approximation of the amount of work involved.

    public String getBooleanString(float value) {
        if (value == 0) return "false";
        return "true";
    }

    public String getThresholdString(float value) {
        return String.valueOf(value);
    }

    public String getValueString(float value) {
        return String.format("%.3f", value);
    }

    // If we have a switch value of less than 0.5, we want it to be 0, and 1 for all others
    public float roundValue(float val) {
        if (val < 0.5) {
            return 0;
        }
        return 1;
    }

    /**
     * @param c A chromosome
     * @return The overall score
     */
    public float scoreNetLogoSolution(Chromosome c) throws FileNotFoundException {

        // Get the various parameter values from the chromosome
        // and use them to set various NetLogo model properties.
        float useMasks = roundValue(c.getGene(0));
        float useLockdown = roundValue(c.getGene(1));
        float useShielding = roundValue(c.getGene(2));
        float useSelfIsolation = roundValue(c.getGene(3));
        float useTestTrace = roundValue(c.getGene(4));
        float useSocialDistancing = roundValue(c.getGene(5));

		float maskThreshold = c.getGene(6) * 100.0f;
		float lockdownThreshold = c.getGene(7) * 100.0f;
		float shieldingThreshold = c.getGene(8) * 100.0f;
		float isolationThreshold = c.getGene(9) * 100.0f;
		float testTraceThreshold = c.getGene(10) * 100.0f;
		float sdThreshold = c.getGene(11) * 100.0f;

//		useMasks = 1;
//		useLockdown = 1;
//		useShielding = 1;
//		useSelfIsolation = 1;
//		useTestTrace = 1;
//		useSocialDistancing = 1;

        ms.setInitialConditions();

        ms.setParameter("ppe?", getBooleanString(useMasks));
        ms.setParameter("lockdown?", getBooleanString(useLockdown));
        ms.setParameter("shielding?", getBooleanString(useShielding));
        ms.setParameter("social-distancing?", getBooleanString(useSocialDistancing));
        ms.setParameter("test-and-trace?", getBooleanString(useTestTrace));
        ms.setParameter("self-isolation?", getBooleanString(useSelfIsolation));

		ms.setParameter("protection-threshold", getValueString(maskThreshold));
		ms.setParameter("lockdown-threshold", getValueString(lockdownThreshold));
		ms.setParameter("shielding-threshold", getValueString(shieldingThreshold));
		ms.setParameter("isolation-threshold", getValueString(isolationThreshold));
		ms.setParameter("test-and-trace-threshold", getValueString(testTraceThreshold));
		ms.setParameter("social-distancing-threshold", getValueString(sdThreshold));

        f = new File(projectPath + "testLog.txt");
        double results = ms.simulate(1, 10, projectPath + "model_data.txt", c);

        float score = (float) results;
        c.setFitness(score);
        evaluations++;
        return score;
    }
}
