
import { GoogleGenAI, Type } from "@google/genai";
import { GeocodeResult } from "../types";

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

export const geocodeLocation = async (query: string): Promise<GeocodeResult> => {
  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: `Convert the following location string into precise latitude and longitude coordinates. 
    Location: "${query}"
    
    Return a JSON object with 'lat', 'lng', and 'displayName'.`,
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          lat: { type: Type.NUMBER },
          lng: { type: Type.NUMBER },
          displayName: { type: Type.STRING }
        },
        required: ["lat", "lng", "displayName"]
      }
    }
  });

  try {
    const data = JSON.parse(response.text || '{}');
    return data as GeocodeResult;
  } catch (error) {
    console.error("Failed to parse geocoding response", error);
    throw new Error("Could not geocode location.");
  }
};
