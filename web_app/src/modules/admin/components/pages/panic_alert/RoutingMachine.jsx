import { useEffect } from "react";
import L from "leaflet";
import "leaflet-routing-machine";
import { useMap } from "react-leaflet";

const RoutingMachine = ({ waypoint1, waypoint2 }) => {
    const map = useMap();

    useEffect(() => {
        if (!map || !waypoint1 || !waypoint2) return;

        const routingControl = L.Routing.control({
            waypoints: [
                L.latLng(waypoint1[0], waypoint1[1]),
                L.latLng(waypoint2[0], waypoint2[1])
            ],
            lineOptions: {
                styles: [{ color: "#0004ff", weight: 5, opacity: 0.7 }]
            },
            show: false, // Sembunyikan panel instruksi teks (turn-by-turn)
            addWaypoints: false,
            routeWhileDragging: false,
            draggableWaypoints: false,
            fitSelectedRoutes: true,
            createMarker: () => null, // Kita sudah punya marker sendiri, jadi jangan buat lagi
        }).addTo(map);

        return () => map.removeControl(routingControl);
    }, [map, waypoint1, waypoint2]);

    return null;
};

export default RoutingMachine;