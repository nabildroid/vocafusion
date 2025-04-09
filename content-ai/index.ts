import * as AI from "./repositories/ai"
import * as Prompts from "./prompts"
import * as fs from "fs/promises"
import * as path from "path"



console.log(await AI.generate({
    system:"you are helful assistant",
    prompt:"generate a random number between 1 and 100"
}));

process.exit();
// Define the flow structure
interface Flow {
    id: string;
    parentId: string | null;
    title: string;
    content: any;
    level: number;
}

export const props = {
    native: "arabic",
    target: "english",
    level: "b2",
    topic: "Advanced Psychological Influence Techniques: Little-Known Behavioral Patterns That Can Intensify Romantic Attraction (For Educational and Ethical Awareness Only)",
    maxLevels: 4, // Control how many levels to generate
    outputFile: "content-tree.json", // Where to save the output
    autosaveInterval: 10 * 1000, // Autosave every 5 minutes (in milliseconds)
    backupFile: "content-tree-backup.json" // Backup file in case of errors
}

// Helper function to create random delays
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
const randomDelay = async () => {
    const delay = Math.floor(Math.random() * 2000) + 1000; // 1-3 seconds
    console.log(`Waiting for ${delay}ms...`);
    await sleep(delay);
};

// Generate unique ID
const generateId = () => `flow_${Date.now()}_${Math.floor(Math.random() * 10000)}`;

// Save flows to file
async function saveFlowsToFile(flows: Flow[], filePath: string) {
    try {
        const outputDir = path.dirname(filePath);
        await fs.mkdir(outputDir, { recursive: true });
        await fs.writeFile(filePath, JSON.stringify(flows, null, 2));
        console.log(`Saved ${flows.length} flows to ${filePath}`);
        return true;
    } catch (error) {
        console.error(`Error saving flows to ${filePath}:`, error);
        return false;
    }
}

// Try to load flows from file
async function loadFlowsFromFile(filePath: string): Promise<Flow[] | null> {
    try {
        const exists = await fs.access(filePath).then(() => true).catch(() => false);
        if (!exists) return null;
        
        const content = await fs.readFile(filePath, 'utf-8');
        return JSON.parse(content) as Flow[];
    } catch (error) {
        console.error(`Error loading flows from ${filePath}:`, error);
        return null;
    }
}

// Generate root content
async function generateRoot(topic: string): Promise<Flow> {
    console.log("Generating root content for:", topic);

    try {
        const root = await AI.generate({
            system: Prompts.RootSystem,
            prompt: `generate a flow about ${topic}

native language is ${props.native}
wanna learn ${props.target} level ${props.level}
generate only 10 vocabulry words but repeat them in different contexts so the total will be 30 items
avoid boring repetition that basically says the same thing `,
        }, { isJson: true, type: "flash" });

        // Validate that the response is an array
        if (!Array.isArray(root)) {
            throw new Error("Root response is not an array");
        }

        return {
            id: generateId(),
            parentId: null,
            title: topic,
            content: root,
            level: 0
        };
    } catch (error) {
        console.error("Error generating root content:", error);
        // Return a simplified flow object with error information
        return {
            id: generateId(),
            parentId: null,
            title: topic,
            content: [{ text: `Error generating content: ${(error as any).message}` }],
            level: 0
        };
    }
}

// Generate branching ideas from a flow
async function generateBranchingIdeas(flow: Flow): Promise<string[]> {
    console.log(`Generating branching ideas from: ${flow.title.substring(0, 30)}...`);

    try {
        // Safely extract text from content
        let contentText;
        if (Array.isArray(flow.content)) {
            contentText = flow.content.map((item: any) => {
                return typeof item === 'object' && item.text ? item.text : String(item);
            }).join("\n");
        } else {
            contentText = String(flow.content);
        }

        const response = await AI.generate({
            system: Prompts.BranchingSystem,
            prompt: `based on the bellow flow generate 3 possible diversion from the given flow
     one is disagree, one agree and one is novel take
        ## Flow
        ${contentText}`
        });

        return response.split("\n").filter((branch: string) => branch.trim().length > 0);
    } catch (error) {
        console.error("Error generating branching ideas:", error);
        // Return a single branch with error info to allow the process to continue
        return [`Error branch: ${(error as any).message}`];
    }
}

// Generate content for a branch
async function generateBranchContent(parentFlow: Flow, branchTitle: string): Promise<Flow> {
    console.log("Generating content for branch:", branchTitle);

    try {
        // Safely extract text from content
        let contentText;
        if (Array.isArray(parentFlow.content)) {
            contentText = parentFlow.content.map((item: any) => {
                return typeof item === 'object' && item.text ? item.text : String(item);
            }).join("\n");
        } else {
            contentText = String(parentFlow.content);
        }

        const response = await AI.generate({
            system: Prompts.RootSystem,
            prompt: `generate a flow about ${branchTitle}
branching out from the Original Flow ${parentFlow.title}
native language ${props.native}
wanna learn ${props.target} level ${props.level}
generate only 10 vocabulry words but repeat them in different contexts so the total will be 30 items
avoid boring repetition that basically says the same thing 

## Original Flow
${contentText}
`
        }, { isJson: true, type: "flash" });

        return {
            id: generateId(),
            parentId: parentFlow.id,
            title: branchTitle,
            content: response,
            level: parentFlow.level + 1
        };
    } catch (error) {
        console.error(`Error generating branch content for "${branchTitle}":`, error);
        // Return a flow object with error information
        return {
            id: generateId(),
            parentId: parentFlow.id,
            title: branchTitle,
            content: [{ text: `Error generating content: ${(error as any).message}` }],
            level: parentFlow.level + 1
        };
    }
}

// Process a level of the tree
async function processLevel(parentFlows: Flow[], allFlows: Flow[], currentLevel: number, lastSaveTime: number): Promise<number> {
    if (currentLevel >= props.maxLevels) {
        console.log(`Reached maximum level (${props.maxLevels}). Stopping.`);
        return lastSaveTime;
    }

    console.log(`\n======== PROCESSING LEVEL ${currentLevel} ========`);
    const newFlows: Flow[] = [];

    for (let i = 0; i < parentFlows.length; i++) {
        const parentFlow = parentFlows[i];
        console.log(`\n---- Processing parent ${i + 1}/${parentFlows.length}: ${parentFlow.title.substring(0, 30)}... ----`);

        await randomDelay();

        const branchTitles = await generateBranchingIdeas(parentFlow);
        console.log(`Generated ${branchTitles.length} branches`);

        for (let j = 0; j < branchTitles.length; j++) {
            const branchTitle = branchTitles[j];
            console.log(`\n-- Branch ${j + 1}/${branchTitles.length}: ${branchTitle.substring(0, 30)}... --`);

            await randomDelay();

            const branchFlow = await generateBranchContent(parentFlow, branchTitle);
            newFlows.push(branchFlow);
            allFlows.push(branchFlow);

            console.log(`Content generated for branch ${branchFlow.id}`);
            
            // Check if it's time for an autosave
            const currentTime = Date.now();
            if (currentTime - lastSaveTime >= props.autosaveInterval) {
                console.log("\n---- PERFORMING AUTO-SAVE ----");
                const outputPath = path.join(process.cwd(), props.outputFile);
                await saveFlowsToFile(allFlows, outputPath);
                
                // Also save a backup
                const backupPath = path.join(process.cwd(), props.backupFile);
                await saveFlowsToFile(allFlows, backupPath);
                
                lastSaveTime = currentTime;
            }
        }
    }

    // If we have new flows and haven't reached the max level, process the next level
    if (newFlows.length > 0 && currentLevel + 1 < props.maxLevels) {
        return await processLevel(newFlows, allFlows, currentLevel + 1, lastSaveTime);
    }
    
    return lastSaveTime;
}

// Main execution
async function main() {
    console.log("Starting tree generation process...");
    
    // Try to load existing flows to continue from where we left off
    const outputPath = path.join(process.cwd(), props.outputFile);
    const backupPath = path.join(process.cwd(), props.backupFile);
    
    let allFlows: Flow[] = [];
    const existingFlows = await loadFlowsFromFile(outputPath) || await loadFlowsFromFile(backupPath);
    
    if (existingFlows && existingFlows.length > 0) {
        console.log(`Found ${existingFlows.length} existing flows. Continuing from where we left off.`);
        allFlows = existingFlows;
        
        // Find the max level already processed
        const maxLevel = Math.max(...allFlows.map(flow => flow.level));
        const rootFlow = allFlows.find(flow => flow.level === 0);
        
        if (rootFlow) {
            console.log(`Root flow exists with ID: ${rootFlow.id}`);
            console.log(`Max level already processed: ${maxLevel}`);
            
            if (maxLevel < props.maxLevels - 1) {
                // Find flows at the current max level to continue processing
                const currentLevelFlows = allFlows.filter(flow => flow.level === maxLevel);
                console.log(`Found ${currentLevelFlows.length} flows at level ${maxLevel} to process.`);
                
                // Continue processing from the current max level
                const lastSaveTime = Date.now();
                await processLevel(currentLevelFlows, allFlows, maxLevel + 1, lastSaveTime);
            } else {
                console.log("All levels have already been processed.");
            }
        } else {
            console.log("Could not find root flow in existing data. Starting fresh.");
            allFlows = [];
        }
    }
    
    // If we didn't have existing flows or couldn't continue, start fresh
    if (allFlows.length === 0) {
        console.log("Starting fresh generation...");
        
        // Generate root flow
        const rootFlow = await generateRoot(props.topic);
        allFlows.push(rootFlow);

        console.log("======== ROOT FLOW ========");
        console.log(`ID: ${rootFlow.id}`);
        console.log(`Title: ${rootFlow.title}`);
        console.log("===========================\n");

        // Process all the levels starting from the root
        const lastSaveTime = Date.now();
        await processLevel([rootFlow], allFlows, 1, lastSaveTime);
    }

    // Final save
    await saveFlowsToFile(allFlows, outputPath);

    console.log(`\n======== TREE GENERATION COMPLETE ========`);
    console.log(`Total flows generated: ${allFlows.length}`);
    console.log(`Tree saved to: ${outputPath}`);
}

await main().catch(error => {
    console.error("Fatal error in main process:", error);
    // Try to save whatever we have before exiting
    const emergencyBackupPath = path.join(process.cwd(), "emergency-backup.json");
    console.log(`Attempting emergency backup to ${emergencyBackupPath}...`);
    // We can't await here since we're in a catch block, but we can try our best
    fs.writeFile(emergencyBackupPath, "{}").catch(e => console.error("Failed even emergency backup:", e));
});