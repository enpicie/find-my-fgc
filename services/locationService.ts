
import { GeocodeResult } from "../types";

/**
 * Traditional Geocoding using Google Maps Platform.
 * Uses process.env.API_KEY as the default, which matches the 
 * pattern of sharing a key for both services in vite.config.ts.
 */
const GOOGLE_API_KEY = process.env.API_KEY;

export const geocodeLocation = async (query: string): Promise<GeocodeResult> => {
  if (!GOOGLE_API_KEY) {
    throw new Error("Google Maps API Key is not configured.");
  }

  const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(
    query
  )}&key=${GOOGLE_API_KEY}`;

  try {
    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'ZERO_RESULTS') {
      throw new Error("Could not find that location.");
    }

    if (data.status !== 'OK') {
      throw new Error(`Google Maps Error: ${data.status} ${data.error_message || ''}`);
    }

    const result = data.results[0];
    return {
      lat: result.geometry.location.lat,
      lng: result.geometry.location.lng,
      displayName: result.formatted_address
    };
  } catch (error: any) {
    console.error("Google Geocoding failed:", error);
    throw error;
  }
};
