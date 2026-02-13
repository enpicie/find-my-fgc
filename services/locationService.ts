
import { GeocodeResult } from "../types";

/**
 * Geocodes a location string using the standard Google Maps Geocoding API.
 * This provides a deterministic, non-AI way to translate user input into coordinates.
 */
export const geocodeLocation = async (query: string): Promise<GeocodeResult> => {
  const apiKey = process.env.API_KEY;
  const encodedQuery = encodeURIComponent(query);
  const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodedQuery}&key=${apiKey}`;

  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Maps API Error: ${response.statusText}`);
    }

    const data = await response.json();

    if (data.status === "ZERO_RESULTS") {
      throw new Error("Location not found. Please try a different search term.");
    }

    if (data.status !== "OK") {
      throw new Error(`Geocoding failed: ${data.error_message || data.status}`);
    }

    const result = data.results[0];
    const { lat, lng } = result.geometry.location;

    return {
      lat,
      lng,
      displayName: result.formatted_address
    };
  } catch (error) {
    console.error("Geocoding service error:", error);
    throw error;
  }
};
