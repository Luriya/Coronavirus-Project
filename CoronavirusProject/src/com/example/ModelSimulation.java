package com.example;

import org.nlogo.api.LogoException;
import org.nlogo.core.CompilerException;
import org.nlogo.headless.HeadlessWorkspace;

import java.io.*;
import java.util.Scanner;
import java.util.stream.DoubleStream;

/**
 * @author 2611955
 * @date 03/04/21
 */
public class ModelSimulation implements Serializable {

    final int noDays = 365;
    // Global Variables
    final HeadlessWorkspace workspace = HeadlessWorkspace.newInstance();
    final boolean debug = false;
    final double averageDailyWage = 80.46;
    final double sdCostPerDay = 10;
    final double lockdownCostPerDay = averageDailyWage * 3;
    final double ppeCostPerDay = 30;
    final double shieldingCostPerDay = averageDailyWage;
    final double isolationCostPerDay = averageDailyWage;
    final double testAndTraceCost = averageDailyWage * 5;
    final int deathCost = 4000;
    final double methodWeighting = 1.0;
    final double infectionWeighting = 12.0;
    double[] runResults;
    double averageInfections;
    FileWriter writer;
    float totalCost;
    float ttIsoSliderValue;
    float ttTraceSliderValue;
    float ttTestCoverageSliderValue;
    double[] averageDailyInfections;
    double[] dailyCost;
    double[][] dailyPopulations;
    double[] averageDailyPopulations;
    double[][] offFromWork;
    double[] averageOffFromWork;
    double[][] unproductiveWorkers;
    double[] averageUnproductive;
    double[][] hospitalAdmissions;
    double[] averageAdmissions;
    double[][] dailyDeaths;
    double[] averageDailyDeaths;
    double isPPEOn;
    double isIsolationOn;
    double isLockdownOn;
    double isShieldingOn;
    double isSDOn;
    double isTTOn;
    double isolationThreshold;
    double ppeThreshold;
    double sdThreshold;
    double shieldingThreshold;
    double lockdownThreshold;
    double isolationCompliance;
    double ppeCompliance;
    double sdCompliance;
    double shieldingCompliance;
    double lockdownCompliance;
    double ttThreshold;
    File myObj;
    Scanner myReader;
    String data;
    String[] arrOfStr;
    int hospitalCost = 400;

    public ModelSimulation(String folder, String model) {
        try {
            workspace.open(folder + model, true);
            //setInitialConditions();
        } catch (Exception e) {
            System.err.println("Something went wrong." + e);
        }
    }

    public static void main(String[] args) throws IOException {
        String filepath = Solver.projectPath; // filepath to write results to
        Scanner myScanner = new Scanner(System.in);


        // User queries
        System.out.println("How many runs do you want to do?");
        int noRuns = myScanner.nextInt();
        System.out.println("Do you want to match against real data?");
        String matching = myScanner.next();

        ModelSimulation ms = new ModelSimulation("[File Location]", "covid-model.nlogo");
        // If we want to match
        if (matching.equals("Y")) {
            System.out.println("How many days do you want to match against?");
            int noDays = myScanner.nextInt();
            ms.dataMatching(noRuns, noDays, filepath);
        }
//        else // We perform the standard simulation instead
//        {
//            System.out.println("How many times to run each set of parameters?");
//            int noLoops = myScanner.nextInt();
//            ms.simulate(noRuns, noLoops, filepath, );
//        }
    }

    public void dataMatching(int noRuns, int noDays, String filepath) throws IOException {

        // Create and open new workspace
        workspace.open("[File Location]" + "covid-model.nlogo", true);

        // Array to hold the data about infections from the NHS file
        double[] dataInfections;
        dataInfections = new double[noDays];

        String targetDataLocation = "[File Location]" + "nhs-covid-data.csv"; // File containing NHS data downloaded from Tableau Public (link in readme file)
        String thisLine;

        // Variables to track highest and lowest value so we can perform normalization
        double dataMinValue = 999999;
        double dataMaxValue = 0;
        int fileCount = 0;

        // Read in from file
        FileInputStream fis = new FileInputStream(targetDataLocation);
        BufferedReader d = new BufferedReader(new InputStreamReader(fis));
        int k = 0;
        String header = d.readLine(); // Skip first line (the headers)
        while (k < noDays) {
            thisLine = d.readLine();
            String[] strar = thisLine.split(",");
            dataInfections[k] = Double.parseDouble(strar[1]);
            if (dataInfections[k] > dataMaxValue) {
                dataMaxValue = dataInfections[k];
            }
            if (dataInfections[k] < dataMinValue) {
                dataMinValue = dataInfections[k];
            }
            //System.out.println("Day " + k + ": " + dataInfections[k]);
            k++;
        }
        // Normalization against the min and max values
        for (k = 0; k < noDays; k++) {
            dataInfections[k] = (dataInfections[k] - dataMinValue) / (dataMaxValue - dataMinValue);
        }

        // 2-dimensional array to store the results of the runs
        double[][] results = new double[noRuns][noDays];
        for (int i = 0; i < noRuns; i++) {
            System.out.println("Run " + (i + 1));
            workspace.command("set number-people 250");
            workspace.command("setup");
            //System.out.println("Total cost: " + workspace.report("total-cost"));
            for (int j = 0; j < noDays; j++) {
                workspace.command("advance");
                results[i][j] = (double) workspace.report("new-infected");
                //System.out.println("New Infected: " + workspace.report("new-infected"));
            }
        }

        PrintWriter out = new PrintWriter(new FileWriter(filepath));

        // Arrays to store information
        double[] averagedResults;
        averagedResults = new double[noDays];
        double[] euclideanDistances;
        euclideanDistances = new double[noDays];

        double minValue = 999999;
        double maxValue = 0;

        // Calculate the average of all the runs, along with the min and max values
        for (int j = 0; j < noDays; j++) {
            for (int i = 0; i < noRuns; i++) {
                averagedResults[j] = averagedResults[j] + results[i][j];
            }
            averagedResults[j] = averagedResults[j] / noRuns;
            if (averagedResults[j] > maxValue) {
                maxValue = averagedResults[j];
            }
            if (averagedResults[j] < minValue) {
                minValue = averagedResults[j];
            }
        }
        System.out.println("Min Value: " + minValue + " Max Value: " + maxValue);

        // Normalization
        for (int i = 0; i < noDays; i++) {
            averagedResults[i] = (averagedResults[i] - minValue) / (maxValue - minValue);
            euclideanDistances[i] = Math.pow((dataInfections[i] - averagedResults[i]), 2);

            //System.out.println(euclideanDistances[i]);
        }

        // Calculate and print the euclidean distance
        double euclideanDist = Math.sqrt(DoubleStream.of(euclideanDistances).sum());
        System.out.println("The Euclidean Distance is: " + euclideanDist);

        // Print results to excel file
        for (int i = 0; i < noDays; i++) {
            out.print(averagedResults[i] + "\t" + dataInfections[i] + "\t");
            for (int j = 0; j < noRuns; j++) {
                out.print("\t" + results[j][i]);
            }
            out.println();
        }
        out.println("\n" + euclideanDist);
        out.close();

        // End program and inform user
        System.out.println("Finished.");
        System.exit(0);
    }

    // Can be used to remotely set parameters if needed
    public void setParameter(String pName, String value) {
        String com = String.format("set %s %s", pName, value);
        workspace.command(com);
    }

    // Setup the initial conditions of the workspace to avoid any issues if the model is changed
    public void setInitialConditions() {
        workspace.command("set simulation-time 365");
        workspace.command("set number-people 400");
        workspace.command("set protection-threshold 5");
        workspace.command("set protection-compliance 90");

        workspace.command("set lockdown-threshold 13");
        workspace.command("set lockdown-compliance 80");

        workspace.command("set shielding-threshold 8");
        workspace.command("set shielding-compliance 70");

        workspace.command("set isolation-threshold 8");
        workspace.command("set isolation-compliance 70");

        workspace.command("set test-and-trace-threshold 10");
        workspace.command("set test-coverage 80");
        workspace.command("set trace-contacts-reached 80");
        workspace.command("set tt-isolation-compliance 65");

        workspace.command("set social-distancing-threshold 5");
        workspace.command("set social-distancing-compliance 90");
        workspace.command("set ppe? true");
        workspace.command("set lockdown? true");
        workspace.command("set shielding? true");
        workspace.command("set self-isolation? true");
        workspace.command("set test-and-trace? true");
        workspace.command("set social-distancing? true");
    }

    // Main method for running the model and returning the results to the evolutionary algorithm
    public double simulate(int noRuns, int noLoops, String filepath, Chromosome chrome) throws FileNotFoundException {

        // Local variables
        double eqnI;
        double eqnM;
        double maxI;
        double normI;
        double maxM;
        double normM;
        workspace.command("delete-file");
        isolationThreshold = (double) workspace.report("isolation-threshold");
        isolationCompliance = (double) workspace.report("isolation-compliance");
        ppeThreshold = (double) workspace.report("protection-threshold");
        ppeCompliance = (double) workspace.report("protection-compliance");
        sdThreshold = (double) workspace.report("social-distancing-threshold");
        sdCompliance = (double) workspace.report("isolation-compliance");
        lockdownThreshold = (double) workspace.report("lockdown-threshold");
        lockdownCompliance = (double) workspace.report("isolation-compliance");
        shieldingThreshold = (double) workspace.report("shielding-threshold");
        shieldingCompliance = (double) workspace.report("isolation-compliance");
        ttThreshold = (double) workspace.report("test-and-trace-threshold");

        workspace.command("setup");
        isPPEOn = (double) workspace.report("b-ppe");
        isIsolationOn = (double) workspace.report("b-iso");
        isLockdownOn = (double) workspace.report("b-lockdown");
        isShieldingOn = (double) workspace.report("b-shield");
        isTTOn = (double) workspace.report("b-tt");
        isSDOn = (double) workspace.report("b-sd");

        averageInfections = 0;
        totalCost = 0;

        // Open the NetLogo model and write to the file given by 'filepath'
        try {
            writer = new FileWriter(filepath);
            if (debug) System.out.println("Writing to text file...");

            writer.write("Run" + "\t" + "Total Cost" + "\t" + "Total Sick" + "\t" + "Total Asymptomatic" + "\t" + "Total Infected" + "\t" + "Total Susceptible" +
                    "\t" + "Total Count" + "\t" + "Total Immune" + "\t" + "Total Deaths" + "\t" + "PPE?" + "\t" + "PPE Threshold" + "\t" + "PPE Compliance" +
                    "\t" + "Lockdown?" + "\t" + "Lockdown Threshold" + "\t" + "Lockdown Compliance" + "\t" + "Shielding?" + "\t" + "Shielding Threshold" + "\t" + "Shielding Compliance" +
                    "\t" + "Isolation?" + "\t" + "Isolation Threshold" + "\t" + "Isolation Compliance" + "\t" + "Test & Trace?" + "\t" + "T&T Threshold" + "\t" + "Test Coverage" +
                    "\t" + "Trace Contacts Reached" + "\t" + "T&T Isolation Compliance" + "\t" + "Social Distancing?" + "\t" + "Social Distancing Threshold" + "\t" + "Social Distancing Compliance" + "\t" + "\n");

            // Set up simulations
            for (int run = 0; run < noRuns; run++) {
                runResults = new double[7];
                String rowNo = Integer.toString(run + 1);

                if (debug) System.out.println("Run " + (run + 1)); // Print run number

                // set up arrays
                double[][] results = new double[noLoops][noDays];
                dailyPopulations = new double[noLoops][noDays];
                offFromWork = new double[noLoops][noDays];
                unproductiveWorkers = new double[noLoops][noDays];
                hospitalAdmissions = new double[noLoops][noDays];
                dailyDeaths = new double[noLoops][noDays];
                averageDailyInfections = new double[noDays];
                averageDailyPopulations = new double[noDays];
                averageOffFromWork = new double[noDays];
                averageUnproductive = new double[noDays];
                averageAdmissions = new double[noDays];
                averageDailyDeaths = new double[noDays];
                dailyCost = new double[noDays];

                // run model for noLoops to get the average - model writes data to file for analysis
                for (int loop = 0; loop < noLoops; loop++) {
                    workspace.command("setup");
                    workspace.command("repeat simulation-time [go]");

                }
                workspace.command("close-file"); // close file to prevent access errors

                // read in from the file the model wrote to
                myObj = new File(Solver.projectPath + "testLog.txt");
                myReader = new Scanner(myObj);
                // for each loop and day, write data to respective entry in 2D array
                for (int loop = 0; loop < noLoops; loop++) {
                    for (int d = 0; d < noDays; d++) {
                        data = myReader.nextLine();
                        arrOfStr = data.split(" ");
                        // index 0 is an empty space - skip to 1
                        results[loop][d] = Double.parseDouble(arrOfStr[1]);
                        //System.out.println("New Infected: " + workspace.report("new-infected"));
                        dailyPopulations[loop][d] = Double.parseDouble(arrOfStr[2]);
                        offFromWork[loop][d] = Double.parseDouble(arrOfStr[3]);
                        unproductiveWorkers[loop][d] = Double.parseDouble(arrOfStr[4]);
                        hospitalAdmissions[loop][d] = Double.parseDouble(arrOfStr[5]);
                        dailyDeaths[loop][d] = Double.parseDouble(arrOfStr[6]);
                    }
                }
                float inf = 0;
                float dea = 0;
                float iCost = 0;
                float mCost = 0;

                // for each day, gather running total of variable values for average
                for (int d = 0; d < noDays; d++) {
                    for (int k = 0; k < noLoops; k++) {
                        averageDailyInfections[d] = averageDailyInfections[d] + results[k][d];
                        averageDailyPopulations[d] = averageDailyPopulations[d] + dailyPopulations[k][d];
                        averageOffFromWork[d] = averageOffFromWork[d] + offFromWork[k][d];
                        averageUnproductive[d] = averageUnproductive[d] + unproductiveWorkers[k][d];
                        averageAdmissions[d] = averageAdmissions[d] + hospitalAdmissions[k][d];
                        averageDailyDeaths[d] = averageDailyDeaths[d] + dailyDeaths[k][d];
                    }
                    // get the average figures for each day based on noLoops
                    averageDailyPopulations[d] = averageDailyPopulations[d] / noLoops;
                    averageDailyInfections[d] = (averageDailyInfections[d] / noLoops);
                    averageOffFromWork[d] = (averageOffFromWork[d] / noLoops);
                    averageUnproductive[d] = (averageUnproductive[d] / noLoops);
                    averageAdmissions[d] = (averageAdmissions[d] / noLoops);
                    averageDailyDeaths[d] = (averageDailyDeaths[d] / noLoops);

//                        eqnI = ((averageDailyInfections[d] * averageDailyWage * averageOffFromWork[d]) +
//                                (averageDailyInfections[d] * averageDailyWage * averageUnproductive[d]) +
//                                (averageDailyInfections[d] * hospitalCost * averageAdmissions[d]) + (averageDailyDeaths[d] * deathCost));

                    // calculate current infection cost
                    eqnI = ((averageDailyInfections[d] * averageDailyWage) + (averageDailyDeaths[d] * deathCost));
//                        maxI = ((averageDailyPopulations[d] * averageDailyWage * averageOffFromWork[d]) +
//                                (averageDailyPopulations[d] * averageDailyWage * averageUnproductive[d]) +
//                                (averageDailyPopulations[d] * hospitalCost * averageAdmissions[d]) + (averageDailyDeaths[d] * deathCost));

                    // worst case infection cost
                    maxI = ((averageDailyPopulations[d] * averageDailyWage) + (averageDailyDeaths[d] * deathCost));
                    if (maxI == 0) {
                        normI = 0;
                    } else {
                        normI = eqnI / maxI; // normalize eqnI against maxI to keep proportion (in case populations change drastically, data still the same)
                    }

                    // calculate current control method cost
                    eqnM = (((isPPEOn * (1 - (ppeThreshold / 100)) * ((ppeCompliance / 100) * averageDailyPopulations[d]) * ppeCostPerDay) +
                            (isLockdownOn * (1 - (lockdownThreshold / 100)) * ((lockdownCompliance / 100) * averageDailyPopulations[d]) * lockdownCostPerDay) +
                            (isSDOn * (1 - (sdThreshold / 100)) * ((sdCompliance / 100) * averageDailyPopulations[d]) * sdCostPerDay) +
                            (isIsolationOn * (1 - (isolationThreshold / 100)) * ((isolationCompliance / 100) * averageDailyPopulations[d]) * isolationCostPerDay) +
                            (isShieldingOn * (1 - (shieldingThreshold / 100)) * ((shieldingCompliance / 100) * averageDailyPopulations[d]) * shieldingCostPerDay) +
                            (isTTOn * testAndTraceCost * (1 - (ttThreshold / 100)))));

                    // calculate worst case control method cost
                    maxM = (((1 * (1 - (0 / 100)) * ((ppeCompliance / 100) * averageDailyPopulations[d]) * ppeCostPerDay) +
                            (1 * (1 - (0 / 100)) * ((lockdownCompliance / 100) * averageDailyPopulations[d]) * lockdownCostPerDay) +
                            (1 * (1 - (0 / 100)) * ((sdCompliance / 100) * averageDailyPopulations[d]) * sdCostPerDay) +
                            (1 * (1 - (0 / 100)) * ((isolationCompliance / 100) * averageDailyPopulations[d]) * isolationCostPerDay) +
                            (1 * (1 - (0 / 100)) * ((shieldingCompliance / 100) * averageDailyPopulations[d]) * shieldingCostPerDay) +
                            (1 * testAndTraceCost * (1 - (0 / 100)))));
                    normM = eqnM / maxM; // same process for normalisation

                    dailyCost[d] = Math.abs((infectionWeighting * normI) + (methodWeighting * normM)); // calculate the cost for each day, using weightings based on how valuable we want each half to be
                    // add to running total for passing to the chromosome methods
                    inf += averageDailyInfections[d];
                    dea += averageDailyDeaths[d];
                    iCost += infectionWeighting * normI;
                    mCost += methodWeighting * normM;
                }

                // use chromosome methods to write data for analysis
                chrome.setInfections(inf / noDays);
                chrome.setTotalInfections(inf);
                chrome.setDeaths(dea / noDays);
                chrome.setTotalDeaths(dea);
                chrome.setICost(iCost / noDays);
                chrome.setMCost(mCost / noDays);
                myReader.close(); // close reader to prevent any issues when looping back through with it open
            }

            // calculate the total cost
            totalCost = (float) DoubleStream.of(dailyCost).sum(); // quick way to sum all of the values in an array (Java 10+?)
            totalCost = totalCost / noDays;
            writer.close(); // close the writer to commit the changes
        }
        // Error handling
        catch (IOException | CompilerException | LogoException e) {
            e.printStackTrace();
        }

        // End program and inform user if needed
        if (debug) System.out.println("Writing to file complete");
        return totalCost;
    }
}

