export interface Booking {
  bookingId: string;
  userId: number;
  parkingId: number;
  parkingName: string;
  location: string;
  slotNumber: string;
  duration: number;
  amount: number;
  status: string;
  bookingCode: string;
  qrCode: string;
  createdAt: string;
}

export const bookings: Booking[] = [];