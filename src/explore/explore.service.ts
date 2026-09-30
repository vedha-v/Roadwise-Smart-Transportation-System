import {
  Injectable,
} from '@nestjs/common';

import { OverpassService } from './overpass.service';

export interface ExploreLocation {
  id: string;
  name: string;
  type: string;
  latitude: number;
  longitude: number;
  distance: number;
  address: string;
  tags: Record<string, any>;
}

@Injectable()
export class ExploreService {
  constructor(
    private readonly overpassService: OverpassService,
  ) {}

  async getNearbyLocations(
    latitude: number,
    longitude: number,
    vehicle: string,
  ) {
    const places =
      await this.overpassService.getNearbyPlaces(
        latitude,
        longitude,
      );

    const locations: ExploreLocation[] = places
      .map(
        (place: any): ExploreLocation | null => {
          const placeLatitude =
            place.lat ??
            place.center?.lat;

          const placeLongitude =
            place.lon ??
            place.center?.lon;

          if (
            typeof placeLatitude !== 'number' ||
            typeof placeLongitude !== 'number'
          ) {
            return null;
          }

          const tags =
            place.tags ?? {};

          const type =
            this.getPlaceType(tags);

          const name =
            tags.name ??
            tags.brand ??
            this.getDefaultName(type);

          const distance =
            this.calculateDistance(
              latitude,
              longitude,
              placeLatitude,
              placeLongitude,
            );

          return {
            id:
              `${place.type}-${place.id}`,

            name,

            type,

            latitude:
              placeLatitude,

            longitude:
              placeLongitude,

            distance:
              Number(distance.toFixed(2)),

            address:
              this.getAddress(tags),

            tags,
          };
        },
      )
      .filter(
        (
          place,
        ): place is ExploreLocation =>
          place !== null,
      )
      .filter(
        (place) =>
          this.isSuitableForVehicle(
            place.type,
            vehicle,
          ),
      )
      .sort(
        (a, b) =>
          a.distance - b.distance,
      );

    return {
      userLocation: {
        latitude,
        longitude,
      },

      vehicleType: vehicle,

      searchRadius: '1 km',

      totalLocations:
        locations.length,

      locations,

      categories: {
        fuelStations:
          locations.filter(
            (location) =>
              location.type === 'fuel',
          ),

        restaurants:
          locations.filter(
            (location) =>
              location.type === 'restaurant',
          ),

        restingSpots:
          locations.filter(
            (location) =>
              location.type === 'rest_area' ||
              location.type === 'truck_stop',
          ),

        highwaySpots:
          locations.filter(
            (location) =>
              location.type === 'highway',
          ),

        evCharging:
          locations.filter(
            (location) =>
              location.type === 'ev_charging',
          ),

        parking:
          locations.filter(
            (location) =>
              location.type === 'parking',
          ),
      },

      message:
        'Real nearby locations retrieved successfully',
    };
  }

  private getPlaceType(
    tags: Record<string, any>,
  ): string {
    if (
      tags.amenity === 'fuel'
    ) {
      return 'fuel';
    }

    if (
      tags.amenity === 'restaurant' ||
      tags.amenity === 'cafe' ||
      tags.amenity === 'fast_food'
    ) {
      return 'restaurant';
    }

    if (
      tags.amenity === 'parking'
    ) {
      return 'parking';
    }

    if (
      tags.amenity ===
      'charging_station'
    ) {
      return 'ev_charging';
    }

    if (
      tags.amenity ===
      'truck_stop'
    ) {
      return 'truck_stop';
    }

    if (
      tags.highway ===
        'rest_area'
    ) {
      return 'rest_area';
    }

    if (
      tags.highway ===
        'services'
    ) {
      return 'rest_area';
    }

    if (
      tags.highway ===
        'motorway_junction'
    ) {
      return 'highway';
    }

    return 'other';
  }

  private getDefaultName(
    type: string,
  ): string {
    switch (type) {
      case 'fuel':
        return 'Fuel Station';

      case 'restaurant':
        return 'Restaurant';

      case 'parking':
        return 'Parking';

      case 'ev_charging':
        return 'EV Charging Station';

      case 'truck_stop':
        return 'Truck Stop';

      case 'rest_area':
        return 'Rest Area';

      case 'highway':
        return 'Highway Junction';

      default:
        return 'Nearby Location';
    }
  }

  private getAddress(
    tags: Record<string, any>,
  ): string {
    const addressParts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:suburb'],
      tags['addr:city'],
      tags['addr:state'],
    ].filter(Boolean);

    if (addressParts.length > 0) {
      return addressParts.join(', ');
    }

    return (
      tags['addr:full'] ??
      tags['description'] ??
      'Address not available'
    );
  }

  private isSuitableForVehicle(
    type: string,
    vehicle: string,
  ): boolean {
    const normalizedVehicle =
      vehicle.toLowerCase();

    if (
      normalizedVehicle.includes(
        'freight',
      ) ||
      normalizedVehicle.includes(
        'truck',
      )
    ) {
      return [
        'fuel',
        'restaurant',
        'rest_area',
        'truck_stop',
        'ev_charging',
        'parking',
        'highway',
      ].includes(type);
    }

    if (
      normalizedVehicle.includes(
        'train',
      )
    ) {
      return [
        'restaurant',
        'parking',
        'ev_charging',
      ].includes(type);
    }

    if (
      normalizedVehicle.includes(
        'bus',
      ) ||
      normalizedVehicle.includes(
        'public',
      )
    ) {
      return [
        'fuel',
        'restaurant',
        'rest_area',
        'parking',
        'ev_charging',
        'highway',
      ].includes(type);
    }

    if (
      normalizedVehicle.includes(
        'two',
      ) ||
      normalizedVehicle.includes(
        'bike',
      )
    ) {
      return [
        'fuel',
        'restaurant',
        'parking',
        'ev_charging',
      ].includes(type);
    }

    return [
      'fuel',
      'restaurant',
      'rest_area',
      'parking',
      'ev_charging',
      'highway',
    ].includes(type);
  }

  private calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const earthRadiusKm =
      6371;

    const latitudeDifference =
      this.toRadians(lat2 - lat1);

    const longitudeDifference =
      this.toRadians(lon2 - lon1);

    const a =
      Math.sin(
        latitudeDifference / 2,
      ) ** 2 +
      Math.cos(
        this.toRadians(lat1),
      ) *
        Math.cos(
          this.toRadians(lat2),
        ) *
        Math.sin(
          longitudeDifference / 2,
        ) ** 2;

    const c =
      2 *
      Math.atan2(
        Math.sqrt(a),
        Math.sqrt(1 - a),
      );

    return earthRadiusKm * c;
  }

  private toRadians(
    degrees: number,
  ): number {
    return (
      degrees *
      (Math.PI / 180)
    );
  }
}