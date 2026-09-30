import {
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';

@Injectable()
export class EvOverpassService {
  private readonly overpassUrl =
    'https://overpass.kumi.systems/api/interpreter';

  async getNearbyChargingStations(
    latitude: number,
    longitude: number,
    radius: number,
  ): Promise<any[]> {
    const query = `
      [out:json][timeout:60];

      (
        nwr(
          around:${radius},
          ${latitude},
          ${longitude}
        )["amenity"="charging_station"];

        nwr(
          around:${radius},
          ${latitude},
          ${longitude}
        )["amenity"="fuel"]["fuel:electricity"="yes"];

        nwr(
          around:${radius},
          ${latitude},
          ${longitude}
        )["amenity"="charging_station"]["access"!="private"];
      );

      out center tags;
    `;

    try {
      console.log(
        `Searching real EV charging stations near ${latitude}, ${longitude}`,
      );

      const response = await fetch(
        this.overpassUrl,
        {
          method: 'POST',

          headers: {
            'Content-Type':
              'application/x-www-form-urlencoded',

            'User-Agent':
              'Roadwise-Smart-Transportation-System',

            Accept: 'application/json',
          },

          body:
            `data=${encodeURIComponent(query)}`,
        },
      );

      if (!response.ok) {
        const errorText =
          await response.text();

        console.error(
          `Overpass HTTP ${response.status}:`,
          errorText,
        );

        throw new Error(
          `Overpass returned HTTP ${response.status}`,
        );
      }

      const data: any =
        await response.json();

      if (
        !data ||
        !Array.isArray(data.elements)
      ) {
        throw new Error(
          'Invalid response from OpenStreetMap',
        );
      }

      console.log(
        `OpenStreetMap returned ${data.elements.length} EV locations`,
      );

      return data.elements;
    } catch (error) {
      console.error(
        'EV OpenStreetMap request failed:',
        error,
      );

      throw new InternalServerErrorException(
        'Unable to retrieve nearby EV charging stations from OpenStreetMap',
      );
    }
  }
}