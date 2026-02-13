import { SearchParams, Tournament } from "../types";

// Note: Ensure the Swift backend is running at this URL
const BACKEND_URL = "http://localhost:8080";

export const fetchTournaments = async (params: SearchParams): Promise<Tournament[]> => {
  console.log("Fetching tournaments with params:", params);
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
    // Check if it's specifically a NetworkError (usually happens if CORS fails or backend is down)
    if (error.name === 'TypeError' && error.message === 'Failed to fetch') {
      console.error("NetworkError: The backend might be offline or CORS policy is blocking the request. Check if the server is running on http://localhost:8080");
    } else {
      console.error("Error fetching tournaments from backend:", error);
    }
    throw error; // Re-throw so the UI can handle or ignore
  }
};