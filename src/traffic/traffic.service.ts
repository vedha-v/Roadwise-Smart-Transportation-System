import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';

const DEFAULT_LATITUDE = 28.6139;
const DEFAULT_LONGITUDE = 77.209;

type TomTomIncident = {
  geometry?: { coordinates?: number[] | number[][] };
  properties?: {
    id?: string;
    iconCategory?: number;
    magnitudeOfDelay?: number;
    from?: string;
    to?: string;
    delay?: number;
    length?: number;
    events?: { description?: string }[];
  };
};

@Injectable()
export class TrafficService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(TrafficService.name);
  private readonly pool: Pool;
  private readonly tomtomApiKey: string;

  constructor(config: ConfigService) {
    this.pool = new Pool({
      connectionString: config.getOrThrow<string>('DATABASE_URL'),
      ssl:
        config.get<string>('DATABASE_SSL') === 'true'
          ? { rejectUnauthorized: false }
          : undefined,
    });
    this.tomtomApiKey = config.get<string>('TOMTOM_API_KEY', '').trim();
  }

  async onModuleInit() {
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS traffic_snapshots (
        id BIGSERIAL PRIMARY KEY,
        latitude DOUBLE PRECISION NOT NULL,
        longitude DOUBLE PRECISION NOT NULL,
        captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        payload JSONB NOT NULL
      );
      CREATE INDEX IF NOT EXISTS traffic_snapshots_location_time_idx
        ON traffic_snapshots (latitude, longitude, captured_at DESC);
    `);
  }

  async onModuleDestroy() {
    await this.pool.end();
  }

  async getTraffic(latitude = DEFAULT_LATITUDE, longitude = DEFAULT_LONGITUDE, radiusMeters = 3000) {
    try {
      if (!this.tomtomApiKey) {
        throw new Error('TOMTOM_API_KEY is not configured');
      }

      const [flow, incidentResponse] = await Promise.all([
        this.fetchFlow(latitude, longitude),
        this.fetchIncidents(latitude, longitude, radiusMeters),
      ]);
      const incidents = this.normalizeIncidents(incidentResponse.incidents ?? []);
      const flowData = flow.flowSegmentData;
      if (!flowData) throw new Error('TomTom returned no flow segment data');

      const payload = {
        source: 'TomTom Traffic API',
        stale: false,
        center: { latitude, longitude },
        capturedAt: new Date().toISOString(),
        status: this.trafficStatus(flowData.currentSpeed, flowData.freeFlowSpeed, flowData.roadClosure),
        congestionPercent: this.congestionPercent(flowData.currentSpeed, flowData.freeFlowSpeed),
        flow: {
          currentSpeed: flowData.currentSpeed,
          freeFlowSpeed: flowData.freeFlowSpeed,
          currentTravelTime: flowData.currentTravelTime,
          freeFlowTravelTime: flowData.freeFlowTravelTime,
          confidence: flowData.confidence,
          roadClosure: flowData.roadClosure,
          coordinates: flowData.coordinates?.coordinate ?? [],
        },
        incidents,
      };

      await this.pool.query(
        `INSERT INTO traffic_snapshots (latitude, longitude, payload)
         VALUES ($1, $2, $3::jsonb)`,
        [latitude, longitude, JSON.stringify(payload)],
      );
      return payload;
    } catch (error) {
      this.logger.warn(`Live TomTom traffic lookup failed: ${String(error)}`);
      const cached = await this.getLatestSnapshot(latitude, longitude);
      if (cached) return { ...cached, stale: true };
      throw new ServiceUnavailableException(
        this.tomtomApiKey
          ? 'TomTom traffic is temporarily unavailable and no saved traffic snapshot exists for this area.'
          : 'Configure TOMTOM_API_KEY to load live traffic. No saved traffic snapshot exists for this area.',
      );
    }
  }

  private async fetchFlow(latitude: number, longitude: number) {
    const url = new URL(
      'https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/10/json',
    );
    url.searchParams.set('key', this.tomtomApiKey);
    url.searchParams.set('point', `${latitude},${longitude}`);
    url.searchParams.set('unit', 'kmph');
    return this.fetchTomTomJson<{ flowSegmentData?: Record<string, any> }>(url);
  }

  private async fetchIncidents(latitude: number, longitude: number, radiusMeters: number) {
    const latitudeDelta = radiusMeters / 111_000;
    const longitudeDelta = radiusMeters / (111_000 * Math.cos((latitude * Math.PI) / 180));
    const url = new URL('https://api.tomtom.com/traffic/services/5/incidentDetails');
    url.searchParams.set('key', this.tomtomApiKey);
    url.searchParams.set(
      'bbox',
      `${longitude - longitudeDelta},${latitude - latitudeDelta},${longitude + longitudeDelta},${latitude + latitudeDelta}`,
    );
    url.searchParams.set(
      'fields',
      '{incidents{type,geometry{type,coordinates},properties{id,iconCategory,magnitudeOfDelay,from,to,delay,length,events{description}}}}',
    );
    url.searchParams.set('language', 'en-GB');
    url.searchParams.set('timeValidityFilter', 'present');
    return this.fetchTomTomJson<{ incidents?: TomTomIncident[] }>(url);
  }

  private async fetchTomTomJson<T>(url: URL): Promise<T> {
    const response = await fetch(url, { signal: AbortSignal.timeout(10000) });
    if (!response.ok) throw new Error(`TomTom returned HTTP ${response.status}`);
    return (await response.json()) as T;
  }

  private normalizeIncidents(incidents: TomTomIncident[]) {
    return incidents.map((incident) => {
      const properties = incident.properties ?? {};
      const coordinates = incident.geometry?.coordinates ?? [];
      const point = typeof coordinates[0] === 'number'
        ? (coordinates as number[])
        : (coordinates as number[][])[Math.floor(coordinates.length / 2)];
      return {
        id: properties.id ?? `${properties.iconCategory ?? 0}-${point?.join(',') ?? 'unknown'}`,
        type: properties.events?.[0]?.description ?? this.incidentType(properties.iconCategory),
        severity: this.incidentSeverity(properties.magnitudeOfDelay),
        from: properties.from ?? null,
        to: properties.to ?? null,
        delaySeconds: properties.delay ?? 0,
        lengthMeters: properties.length ?? null,
        latitude: point?.[1] ?? null,
        longitude: point?.[0] ?? null,
      };
    });
  }

  private incidentType(category?: number) {
    return (
      {
        1: 'Accident',
        2: 'Fog',
        3: 'Hazardous conditions',
        4: 'Rain',
        5: 'Ice',
        6: 'Traffic jam',
        7: 'Lane closed',
        8: 'Road closed',
        9: 'Roadworks',
        10: 'Wind',
        11: 'Flooding',
        14: 'Breakdown',
      }[category ?? 0] ?? 'Traffic incident'
    );
  }

  private incidentSeverity(magnitude?: number) {
    return ({ 1: 'Minor', 2: 'Moderate', 3: 'Major', 4: 'Road closure' } as Record<number, string>)[magnitude ?? 0] ?? 'Unknown';
  }

  private congestionPercent(currentSpeed: number, freeFlowSpeed: number) {
    if (!freeFlowSpeed) return 0;
    return Math.max(0, Math.min(100, Math.round((1 - currentSpeed / freeFlowSpeed) * 100)));
  }

  private trafficStatus(currentSpeed: number, freeFlowSpeed: number, roadClosure: boolean) {
    if (roadClosure) return 'Closed';
    const congestion = this.congestionPercent(currentSpeed, freeFlowSpeed);
    if (congestion >= 60) return 'Heavy';
    if (congestion >= 30) return 'Moderate';
    return 'Free flowing';
  }

  private async getLatestSnapshot(latitude: number, longitude: number) {
    const result = await this.pool.query<{ payload: Record<string, unknown> }>(
      `SELECT payload FROM traffic_snapshots
       WHERE ABS(latitude - $1) <= 0.03 AND ABS(longitude - $2) <= 0.03
       ORDER BY ((latitude - $1) * (latitude - $1) + (longitude - $2) * (longitude - $2)), captured_at DESC
       LIMIT 1`,
      [latitude, longitude],
    );
    return result.rows[0]?.payload;
  }
}