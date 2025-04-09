import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_KEY!);

const PRO = genAI.getGenerativeModel({
    model: "gemini-2.5-pro-exp-03-25",
});

const FLASH = genAI.getGenerativeModel({
    model: "gemini-2.0-flash",
});


export async function generate(props: {
    system: string,
    prompt: string,
}, config?: {
    type?: "flash" | "pro",
    isJson?: boolean,
}) {
    const model = config?.type === "pro" ? PRO : FLASH;
    const generator = await model.generateContent({
        contents: [{
            role: "user",
            parts: [{
                text: props.prompt,
            }]
        }],
        systemInstruction: props.system,
        generationConfig: {
            responseMimeType: config?.isJson ? "application/json" : "text/plain",
        }
    },)

    const response = generator.response.text();
    if (config?.isJson) {
        return JSON.parse(response);
    }
    return response;
}