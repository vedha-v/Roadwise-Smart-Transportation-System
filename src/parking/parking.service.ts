import {
  BadGatewayException,
  BadRequestException,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';

const DELHI_LAT = 28.6329;
const DELHI_LON = 77.2195;
const DEMO_OSM_ID = '1';
const OVERPASS_URLS = [
  'https://overpass.openstreetmap.fr/api/interpreter',
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

type OSMParking = {
  type: 'node' | 'way' | 'relation';
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
};

@Injectable()
export class ParkingService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ParkingService.name);
  private readonly pool: Pool;

  constructor(config: ConfigService) {
    this.pool = new Pool({
      connectionString: config.getOrThrow<string>('DATABASE_URL'),
      ssl: config.get<string>('DATABASE_SSL') === 'true'
        ? { rejectUnauthorized: false }
        : undefined,
    });
  }

  async onModuleInit() {
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS parking_facilities (
        id BIGSERIAL PRIMARY KEY,
        osm_type TEXT NOT NULL,
        osm_id BIGINT NOT NULL,
        name TEXT NOT NULL,
        latitude DOUBLE PRECISION NOT NULL,
        longitude DOUBLE PRECISION NOT NULL,
        tags JSONB NOT NULL DEFAULT '{}'::jsonb,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (osm_type, osm_id)
      );
      CREATE TABLE IF NOT EXISTS parking_slots (
        id BIGSERIAL PRIMARY KEY,
        facility_id BIGINT NOT NULL REFERENCES parking_facilities(id) ON DELETE CASCADE,
        slot_code TEXT NOT NULL,
        verified_by TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (facility_id, slot_code)
      );
      CREATE TABLE IF NOT EXISTS parking_reservations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id TEXT NOT NULL,
        slot_id BIGINT NOT NULL REFERENCES parking_slots(id),
        starts_at TIMESTAMPTZ NOT NULL,
        ends_at TIMESTAMPTZ NOT NULL,
        status TEXT NOT NULL DEFAULT 'confirmed',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CHECK (ends_at > starts_at)
      );
      CREATE INDEX IF NOT EXISTS parking_reservations_slot_time_idx
        ON parking_reservations (slot_id, starts_at, ends_at)
        WHERE status = 'confirmed';
    `);

    if (process.env.PARKING_DEMO_MODE === 'true') {
      const demoFacility = await this.pool.query(
        `INSERT INTO parking_facilities (osm_type, osm_id, name, latitude, longitude, tags)
         VALUES ('demo', $1, 'Reviewer Demo Parking (sample only)', $2, $3,
           '{"source":"RoadWise demo fixture","realFacility":false}'::jsonb)
         ON CONFLICT (osm_type, osm_id) DO UPDATE SET
           name = EXCLUDED.name, latitude = EXCLUDED.latitude,
           longitude = EXCLUDED.longitude, tags = EXCLUDED.tags
         RETURNING id`,
        [DEMO_OSM_ID, DELHI_LAT + 0.002, DELHI_LON + 0.002],
      );
      for (const slotCode of ['DEMO-01', 'DEMO-02', 'DEMO-03']) {
        await this.pool.query(
          `INSERT INTO parking_slots (facility_id, slot_code, verified_by)
           VALUES ($1, $2, 'DEMO ONLY - NOT REAL INVENTORY')
           ON CONFLICT (facility_id, slot_code) DO NOTHING`,
          [demoFacility.rows[0].id, slotCode],
        );
      }
    }
  }

  async onModuleDestroy() {
    await this.pool.end();
  }

  async getNearbyParking(radiusMeters: number) {
    const query = `[out:json][timeout:20];nwr(around:${radiusMeters},${DELHI_LAT},${DELHI_LON})["amenity"="parking"];out center tags;`;
    let response: Response | undefined;
    let lastError: unknown;
    for (const url of OVERPASS_URLS) {
      try {
        const candidate = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'User-Agent': 'RoadWise/1.0 (OpenStreetMap parking discovery)',
          },
          body: new URLSearchParams({ data: query }),
          signal: AbortSignal.timeout(15000),
        });
        if (candidate.ok) {
          response = candidate;
          break;
        }
        lastError = new Error(`Overpass returned ${candidate.status}`);
        this.logger.warn(`${url} returned ${candidate.status}; trying another OSM mirror`);
      } catch (error) {
        lastError = error;
        this.logger.warn(`${url} failed; trying another OSM mirror`);
      }
    }
    let osmUnavailable = false;
    if (!response) {
      this.logger.warn(`All OpenStreetMap Overpass mirrors failed: ${String(lastError)}`);
      osmUnavailable = true;
    }

    let elements: OSMParking[] = [];
    if (response) {
      try {
        const result = (await response.json()) as { elements?: OSMParking[] };
        elements = result.elements ?? [];
      } catch (error) {
        this.logger.warn(`Could not parse Overpass response: ${String(error)}`);
        osmUnavailable = true;
      }
    }
    elements = elements.filter(
      (item) => this.coordinates(item) && this.osmFacilityName(item.tags ?? {}),
    );
    const facilities = [];
    for (const item of elements) {
      const point = this.coordinates(item)!;
      const tags = item.tags ?? {};
      const name = this.osmFacilityName(tags)!;
      const saved = await this.pool.query(
        `INSERT INTO parking_facilities (osm_type, osm_id, name, latitude, longitude, tags)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (osm_type, osm_id) DO UPDATE SET
           name = EXCLUDED.name, latitude = EXCLUDED.latitude,
           longitude = EXCLUDED.longitude, tags = EXCLUDED.tags, updated_at = NOW()
         RETURNING id`,
        [item.type, item.id, name, point.lat, point.lon, JSON.stringify(tags)],
      );
      const inventory = await this.pool.query(
        `SELECT COUNT(*)::int AS slot_count FROM parking_slots WHERE facility_id = $1`,
        [saved.rows[0].id],
      );
      facilities.push({
        osmType: item.type,
        osmId: String(item.id),
        name,
        latitude: point.lat,
        longitude: point.lon,
        distanceKm: Number(this.distanceKm(point.lat, point.lon).toFixed(2)),
        tags,
        verifiedSlotCount: inventory.rows[0].slot_count as number,
        osmUrl: `https://www.openstreetmap.org/${item.type}/${item.id}`,
        isDemo: false,
      });
    }
    if (process.env.PARKING_DEMO_MODE === 'true') {
      const demo = await this.pool.query(
        `SELECT f.latitude, f.longitude,
           (SELECT COUNT(*)::int FROM parking_slots s WHERE s.facility_id = f.id) AS slot_count
         FROM parking_facilities f WHERE f.osm_type = 'demo' AND f.osm_id = $1`,
        [DEMO_OSM_ID],
      );
      const demoRecord = demo.rows[0];
      if (demoRecord) {
        facilities.push({
          osmType: 'demo',
          osmId: DEMO_OSM_ID,
          name: 'Reviewer Demo Parking (sample only)',
          latitude: demoRecord.latitude,
          longitude: demoRecord.longitude,
          distanceKm: Number(
            this.distanceKm(demoRecord.latitude, demoRecord.longitude).toFixed(2),
          ),
          tags: { source: 'RoadWise demo fixture', realFacility: false },
          verifiedSlotCount: demoRecord.slot_count as number,
          isDemo: true,
        });
      }
    }
    return {
      facilities,
      source: osmUnavailable ? 'OpenStreetMap (temporarily unavailable)' : 'OpenStreetMap',
      attribution: '© OpenStreetMap contributors',
      ...(osmUnavailable ? { warning: 'Only the explicitly labeled demo facility is shown because Overpass could not be reached.' } : {}),
    };
  }

  async getAvailableSlots(input: {
    osmType: string;
    osmId: string;
    startsAt: string;
    endsAt: string;
  }) {
    const { startsAt, endsAt } = this.validateInterval(input.startsAt, input.endsAt);
    const facility = await this.findFacility(input.osmType, input.osmId);
    if (!facility) return { slots: [] };
    const result = await this.pool.query(
      `SELECT s.id, s.slot_code AS "slotCode"
       FROM parking_slots s
       WHERE s.facility_id = $1
         AND NOT EXISTS (
           SELECT 1 FROM parking_reservations r
           WHERE r.slot_id = s.id AND r.status = 'confirmed'
             AND r.starts_at < $3 AND r.ends_at > $2
         )
       ORDER BY s.slot_code`,
      [facility.id, startsAt, endsAt],
    );
    return { slots: result.rows };
  }

  async addVerifiedInventory(input: {
    osmType?: string;
    osmId?: string;
    slots?: string[];
    verifiedBy?: string;
  }) {
    if (!input.osmType || !input.osmId || !input.verifiedBy?.trim() ||
        !Array.isArray(input.slots) || input.slots.length === 0 || input.slots.length > 500) {
      throw new BadRequestException('Provide OSM identity, verifier, and 1-500 real slot codes');
    }
    const facility = await this.findFacility(input.osmType, input.osmId);
    if (!facility) {
      throw new BadRequestException('Discover this OSM facility before registering its verified slots');
    }
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      for (const slotCode of input.slots) {
        const code = slotCode.trim();
        if (!code) throw new BadRequestException('Slot codes cannot be empty');
        await client.query(
          `INSERT INTO parking_slots (facility_id, slot_code, verified_by)
           VALUES ($1, $2, $3) ON CONFLICT (facility_id, slot_code) DO NOTHING`,
          [facility.id, code, input.verifiedBy.trim()],
        );
      }
      await client.query('COMMIT');
      return { added: input.slots.length, facility: `${input.osmType}/${input.osmId}` };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async createReservation(input: {
    userId?: string;
    slotId?: number;
    startsAt?: string;
    endsAt?: string;
  }) {
    const userId = input.userId?.trim() || 'demo-user';
    const slotId = Number(input.slotId);
    if (!Number.isSafeInteger(slotId) || slotId <= 0) {
      throw new BadRequestException('slotId must be a positive integer');
    }
    const { startsAt, endsAt } = this.validateInterval(input.startsAt, input.endsAt);
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('SELECT pg_advisory_xact_lock($1::bigint)', [slotId]);
      const slot = await client.query(
        `SELECT s.id FROM parking_slots s JOIN parking_facilities f ON f.id = s.facility_id
         WHERE s.id = $1`,
        [slotId],
      );
      if (slot.rowCount === 0) throw new BadRequestException('Slot does not exist in verified inventory');
      const overlap = await client.query(
        `SELECT 1 FROM parking_reservations WHERE slot_id = $1 AND status = 'confirmed'
         AND starts_at < $3 AND ends_at > $2 LIMIT 1`,
        [slotId, startsAt, endsAt],
      );
      if (overlap.rowCount) throw new BadRequestException('This slot is already reserved during that time');
      const reservation = await client.query(
        `INSERT INTO parking_reservations (user_id, slot_id, starts_at, ends_at)
         VALUES ($1, $2, $3, $4) RETURNING id AS "bookingId", slot_id AS "slotId",
           starts_at AS "startsAt", ends_at AS "endsAt", status`,
        [userId, slotId, startsAt, endsAt],
      );
      await client.query('COMMIT');
      return reservation.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getReservations(userId = 'demo-user') {
    const result = await this.pool.query(
      `SELECT r.id AS "bookingId", r.user_id AS "userId", s.slot_code AS slot,
         f.name AS "parkingName", f.osm_type AS "osmType", f.osm_id AS "osmId",
         r.starts_at AS "startsAt", r.ends_at AS "endsAt", r.status
       FROM parking_reservations r
       JOIN parking_slots s ON s.id = r.slot_id
       JOIN parking_facilities f ON f.id = s.facility_id
       WHERE r.user_id = $1 ORDER BY r.starts_at DESC`,
      [userId],
    );
    return { bookings: result.rows };
  }

  private async findFacility(osmType: string, osmId: string) {
    const validOsmIdentity = ['node', 'way', 'relation'].includes(osmType) && /^\d+$/.test(osmId);
    const validDemoIdentity = osmType === 'demo' && osmId === DEMO_OSM_ID;
    if (!validOsmIdentity && !validDemoIdentity) {
      throw new BadRequestException('Invalid OpenStreetMap facility identity');
    }
    const result = await this.pool.query(
      'SELECT id FROM parking_facilities WHERE osm_type = $1 AND osm_id = $2',
      [osmType, osmId],
    );
    return result.rows[0] as { id: string } | undefined;
  }

  private osmFacilityName(tags: Record<string, string>) {
    for (const key of ['name', 'name:en', 'official_name', 'brand']) {
      const name = tags[key]?.trim();
      if (name) return name;
    }
    return undefined;
  }

  private validateInterval(startsAt?: string, endsAt?: string) {
    const start = startsAt ? new Date(startsAt) : new Date(NaN);
    const end = endsAt ? new Date(endsAt) : new Date(NaN);
    if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime()) || end <= start ||
        start <= new Date() || end.getTime() - start.getTime() > 24 * 60 * 60 * 1000) {
      throw new BadRequestException('Provide a future time range no longer than 24 hours');
    }
    return { startsAt: start.toISOString(), endsAt: end.toISOString() };
  }

  private coordinates(item: OSMParking) {
    const lat = item.lat ?? item.center?.lat;
    const lon = item.lon ?? item.center?.lon;
    return lat === undefined || lon === undefined ? undefined : { lat, lon };
  }

  private distanceKm(latitude: number, longitude: number) {
    const radians = (degrees: number) => degrees * Math.PI / 180;
    const deltaLat = radians(latitude - DELHI_LAT);
    const deltaLon = radians(longitude - DELHI_LON);
    const term = Math.sin(deltaLat / 2) ** 2 +
      Math.cos(radians(DELHI_LAT)) * Math.cos(radians(latitude)) * Math.sin(deltaLon / 2) ** 2;
    return 6371 * 2 * Math.atan2(Math.sqrt(term), Math.sqrt(1 - term));
  }
}