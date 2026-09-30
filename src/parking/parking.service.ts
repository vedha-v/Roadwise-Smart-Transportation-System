import { Injectable, NotFoundException } from '@nestjs/common';
import { parkingData, Parking } from './parking.data';

@Injectable()
export class ParkingService {

  getAllParking() {
    return {
      parking: parkingData,
      message: 'Parking locations available',
    };
  }

  getNearbyParking(
    latitude: number,
    longitude: number,
  ) {
    const nearbyParking = parkingData.map(
      (parking: Parking) => {

        const distance = this.calculateDistance(
          latitude,
          longitude,
          parking.latitude,
          parking.longitude,
        );

        return {
          ...parking,
          distance: distance.toFixed(2) + ' km',
        };
      },
    );

    nearbyParking.sort(
      (a, b) =>
        parseFloat(a.distance) -
        parseFloat(b.distance),
    );

    return {
      userLocation: {
        latitude,
        longitude,
      },
      nearbyParking,
      message: 'Nearby parking locations',
    };
  }

  getParkingById(id: number) {
    const parking = parkingData.find(
      (item: Parking) => item.id === id,
    );

    if (!parking) {
      throw new NotFoundException(
        'Parking location not found',
      );
    }

    return {
      parking,
      message: 'Parking location found',
    };
  }

  private calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {

    const R = 6371;

    const dLat =
      (lat2 - lat1) * Math.PI / 180;

    const dLon =
      (lon2 - lon1) * Math.PI / 180;

    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(lat1 * Math.PI / 180) *
      Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) ** 2;

    const c =
      2 *
      Math.atan2(
        Math.sqrt(a),
        Math.sqrt(1 - a),
      );

    return R * c;
  }
}