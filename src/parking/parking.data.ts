export interface Parking {
  id: number;
  name: string;
  city: string;
  location: string;
  latitude: number;
  longitude: number;
  totalSlots: number;
  availableSlots: number;
  pricePerHour: number;
}

export const parkingData: Parking[] = [
  {
    id: 1,
    name: 'Connaught Central Parking',
    city: 'Delhi',
    location: 'Connaught Place',
    latitude: 28.6328,
    longitude: 77.2197,
    totalSlots: 250,
    availableSlots: 87,
    pricePerHour: 50,
  },

  {
    id: 2,
    name: 'Baba Kharak Singh Road Parking',
    city: 'Delhi',
    location: 'Baba Kharak Singh Marg',
    latitude: 28.6302,
    longitude: 77.2168,
    totalSlots: 180,
    availableSlots: 42,
    pricePerHour: 40,
  },

  {
    id: 3,
    name: 'Karol Bagh City Parking',
    city: 'Delhi',
    location: 'Karol Bagh',
    latitude: 28.6519,
    longitude: 77.1909,
    totalSlots: 220,
    availableSlots: 96,
    pricePerHour: 40,
  },

  {
    id: 4,
    name: 'India Gate Central Parking',
    city: 'Delhi',
    location: 'India Gate',
    latitude: 28.6129,
    longitude: 77.2295,
    totalSlots: 300,
    availableSlots: 124,
    pricePerHour: 50,
  },

  {
    id: 5,
    name: 'Pandara Road Parking',
    city: 'Delhi',
    location: 'Pandara Road, India Gate',
    latitude: 28.6087,
    longitude: 77.2291,
    totalSlots: 160,
    availableSlots: 51,
    pricePerHour: 40,
  },

  {
    id: 6,
    name: 'New Delhi Railway Parking',
    city: 'Delhi',
    location: 'Ajmeri Gate, New Delhi Railway Station',
    latitude: 28.6431,
    longitude: 77.2183,
    totalSlots: 350,
    availableSlots: 142,
    pricePerHour: 60,
  },

  {
    id: 7,
    name: 'IGI Airport Terminal Parking',
    city: 'Delhi',
    location: 'IGI Airport Terminal 3',
    latitude: 28.5562,
    longitude: 77.1000,
    totalSlots: 1000,
    availableSlots: 386,
    pricePerHour: 80,
  },

  {
    id: 8,
    name: 'Lajpat Nagar Market Parking',
    city: 'Delhi',
    location: 'Central Market, Lajpat Nagar',
    latitude: 28.5677,
    longitude: 77.2433,
    totalSlots: 200,
    availableSlots: 73,
    pricePerHour: 40,
  },

  {
    id: 9,
    name: 'Green Park Market Parking',
    city: 'Delhi',
    location: 'Green Park',
    latitude: 28.5598,
    longitude: 77.2067,
    totalSlots: 150,
    availableSlots: 58,
    pricePerHour: 40,
  },

  {
    id: 10,
    name: 'Rajouri Garden Parking',
    city: 'Delhi',
    location: 'Rajouri Garden',
    latitude: 28.6469,
    longitude: 77.1224,
    totalSlots: 240,
    availableSlots: 109,
    pricePerHour: 50,
  },
];