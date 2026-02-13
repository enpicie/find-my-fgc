
import { SearchParams, Tournament } from "../types";

/**
 * The backend URL should be set via environment variables.
 * In development, this is usually http://localhost:8080.
 * In production, this would be your AWS ALB or API Gateway URL (e.g., https://api.findmyfgc.com).
 */
const BACKEND_URL = process.env.VITE_BACKEND_URL || "http://localhost:8080";

export const fetchTournaments = async (params: SearchParams): Promise<Tournament[]> => {
  console.log(`Fetching tournaments from: ${BACKEND_URL}/tournaments`);
  try {
    const response = await fetch(`${BACKEND_URL}/tournaments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        lat: params.lat,
        lng: params.lng,
        radius: `${params.radius}mi`,
        gameIds: params.gameIds
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Backend Error (${response.status}):`, errorText);
      throw new Error(`Backend Error: ${errorText}`);
    }

    const data = await response.json();
    return data as Tournament[];
  } catch (error: any) {
    if (error.name === 'TypeError' && error.message === 'Failed to fetch') {
      console.error(`NetworkError: Could not reach ${BACKEND_URL}. Check if the server is running and CORS is configured for this origin.`);
    } else {
      console.error("Error fetching tournaments from backend:", error);
    }
    throw error;
  }
};
