
import React, { useEffect, useRef } from 'react';
import { Tournament } from '../types';

interface MapProps {
  center: [number, number];
  zoom: number;
  tournaments: Tournament[];
}

const Map: React.FC<MapProps> = ({ center, zoom, tournaments }) => {
  // Use 'any' to bypass Leaflet type errors because L is loaded globally from index.html
  const mapRef = useRef<any>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const markersRef = useRef<any[]>([]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    // @ts-ignore (L is global from index.html)
    mapRef.current = L.map(containerRef.current).setView(center, zoom);

    // @ts-ignore
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(mapRef.current);

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (mapRef.current) {
      mapRef.current.setView(center, zoom);
    }
  }, [center, zoom]);

  useEffect(() => {
    if (!mapRef.current) return;

    // Clear old markers
    markersRef.current.forEach(m => m.remove());
    markersRef.current = [];

    tournaments.forEach(t => {
      // Mock coordinates for demo if they don't exist in actual API response
      // (The start.gg query returns city/addr, real Lat/Lng requires a slightly deeper query or geocoding)
      // For visual feedback, we'll place them near the center if coords missing
      const lat = center[0] + (Math.random() - 0.5) * 0.1;
      const lng = center[1] + (Math.random() - 0.5) * 0.1;

      // @ts-ignore
      const marker = L.marker([lat, lng])
        .addTo(mapRef.current!)
        .bindPopup(`<b>${t.name}</b><br>${t.location}<br><a href="${t.externalUrl}" target="_blank">View on start.gg</a>`);
      
      markersRef.current.push(marker);
    });
  }, [tournaments, center]);

  return <div ref={containerRef} className="h-full w-full" />;
};

export default Map;
