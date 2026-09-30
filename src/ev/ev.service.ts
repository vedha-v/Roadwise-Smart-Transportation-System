import { Injectable } from '@nestjs/common';

import { EvOverpassService } from './ev-overpass.service';

export interface EvChargingStation {
  id: string;
  name: string;
  type: string;
  latitude: number;
  longitude: number;
  distance: number;
  address: string;
  operator: string | null;
  brand: string | null;
  chargingCapacity: string | null;
  connectorTypes: string[];
  access: string | null;
  openingHours: string | null;
  tags: Record<string, any>;
}

@Injectable()
export class EvService {
  constructor(
    private readonly evOverpassService: EvOverpassService,
  ) {}

  async getNearbyChargingStations(
    latitude: number,
    longitude: number,
    radius: number,
  ) {
    const places =
      await this.evOverpassService.getNearbyChargingStations(
        latitude,
        longitude,
        radius,
      );

    const stations: EvChargingStation[] = [];

    for (const place of places) {
      const stationLatitude =
        place.lat ?? place.center?.lat;

      const stationLongitude =
        place.lon ?? place.center?.lon;

      if (
        typeof stationLatitude !== 'number' ||
        typeof stationLongitude !== 'number'
      ) {
        continue;
      }

      const tags =
        place.tags ?? {};

      const distance =
        this.calculateDistance(
          latitude,
          longitude,
          stationLatitude,
          stationLongitude,
        );

      stations.push({
        id: `${place.type}-${place.id}`,

        name:
          tags.name ??
          tags.brand ??
          'EV Charging Station',

        type: 'ev_charging',

        latitude: stationLatitude,

        longitude: stationLongitude,

        distance: Number(
          distance.toFixed(2),
        ),

        address:
          this.getAddress(tags),

        operator:
          tags.operator ?? null,

        brand:
          tags.brand ?? null,

        chargingCapacity:
          tags.capacity ??
          tags['capacity:charging'] ??
          null,

        connectorTypes:
          this.getConnectorTypes(tags),

        access:
          tags.access ?? null,

        openingHours:
          tags.opening_hours ?? null,

        tags,
      });
    }

    stations.sort(
      (a, b) =>
        a.distance - b.distance,
    );

    return {
      userLocation: {
        latitude,
        longitude,
      },

      searchRadius:
        `${radius} meters`,

      totalStations:
        stations.length,

      stations,

      message:
        'Real nearby EV charging stations retrieved successfully',
    };
  }

  private getConnectorTypes(
    tags: Record<string, any>,
  ): string[] {
    const connectors: string[] = [];

    const possibleConnectors = [
      'socket:type2',
      'socket:type2_combo',
      'socket:chademo',
      'socket:ccs',
      'socket:tesla_supercharger',
      'socket:tesla_destination',
      'socket:schuko',
    ];

    for (const connector of possibleConnectors) {
      if (
        tags[connector] !== undefined &&
        tags[connector] !== null &&
        tags[connector] !== 'no'
      ) {
        connectors.push(connector);
      }
    }

    return connectors;
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
      tags['addr:postcode'],
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

  private calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const earthRadiusKm = 6371;

    const latitudeDifference =
      this.toRadians(
        lat2 - lat1,
      );

    const longitudeDifference =
      this.toRadians(
        lon2 - lon1,
      );

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