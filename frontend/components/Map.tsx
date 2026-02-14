import React, { useEffect, useRef } from 'react';
import { Tournament } from '../types';

interface MapProps {
  center: [number, number];
  zoom: number;
  tournaments: Tournament[];
}

const Map: React.FC<MapProps> = ({ center, zoom, tournaments }) => {
  const mapRef = useRef<any>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const markersRef = useRef<any[]>([]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    // @ts-ignore
    mapRef.current = L.map(containerRef.current, {
      zoomControl: false
    }).setView(center, zoom);

    // @ts-ignore
    L.control.zoom({ position: 'bottomright' }).addTo(mapRef.current);

    // @ts-ignore
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(mapRef.current);

    const resizeObserver = new ResizeObserver(() => {
      if (mapRef.current) {
        mapRef.current.invalidateSize();
      }
    });

    if (containerRef.current) {
      resizeObserver.observe(containerRef.current);
    }

    return () => {
      resizeObserver.disconnect();
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (mapRef.current) {
      mapRef.current.setView(center, zoom);
      mapRef.current.invalidateSize();
    }
  }, [center, zoom]);

  useEffect(() => {
    if (!mapRef.current) return;

    markersRef.current.forEach(m => m.remove());
    markersRef.current = [];

    tournaments.forEach(t => {
      const lat = center[0] + (Math.random() - 0.5) * 0.05;
      const lng = center[1] + (Math.random() - 0.5) * 0.05;

      // @ts-ignore
      const marker = L.marker([lat, lng])
        .addTo(mapRef.current!)
        .bindPopup(`
          <div class="text-slate-900 p-1">
            <strong class="block text-sm">${t.name}</strong>
            <span class="text-xs block text-slate-500 mb-2">${t.location}</span>
            <a href="${t.externalUrl}" target="_blank" class="text-indigo-600 font-bold text-xs underline">View on start.gg</a>
          </div>
        `);
      
      markersRef.current.push(marker);
    });
  }, [tournaments, center]);

  return <div ref={containerRef} className="h-full w-full bg-slate-800" />;
};

export default Map;