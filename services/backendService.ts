
import { SearchParams, UnifiedSearchResponse } from "../types";

const BACKEND_URL = process.env.VITE_BACKEND_URL || "http://localhost:8080";

export const performUnifiedSearch = async (params: SearchParams): Promise<UnifiedSearchResponse> => {
  try {
    const response = await fetch(`${BACKEND_URL}/tournaments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: params.query,
        radius: `${params.radius}mi`,
        gameIds: params.gameIds
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(errorText || "Failed to fetch results from server.");
    }

    return await response.json() as UnifiedSearchResponse;
  } catch (error: any) {
    console.error("Unified search failed:", error);
    throw error;
  }
};
