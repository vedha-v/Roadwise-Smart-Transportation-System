import {
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';

@Injectable()
export class OverpassService {
  private readonly overpassUrl =
    'https://overpass.kumi.systems/api/interpreter';

  async getNearbyPlaces(
    latitude: number,
    longitude: number,
  ): Promise<any[]> {
    const query = `
      [out:json][timeout:60];

      (
        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["amenity"="fuel"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["amenity"="restaurant"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["amenity"="cafe"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["amenity"="fast_food"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["amenity"="parking"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["amenity"="charging_station"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["amenity"="truck_stop"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["highway"="rest_area"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["highway"="services"];

        nwr(
          around:1000,
          ${latitude},
          ${longitude}
        )["highway"="motorway_junction"];
      );

      out center tags;
    `;

    try {
      console.log(
        `Searching OpenStreetMap near ${latitude}, ${longitude}`,
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
        `OpenStreetMap returned ${data.elements.length} locations`,
      );

      return data.elements;
    } catch (error) {
      console.error(
        'OpenStreetMap request failed:',
        error,
      );

      throw new InternalServerErrorException(
        'Unable to retrieve nearby locations from OpenStreetMap',
      );
    }
  }
}