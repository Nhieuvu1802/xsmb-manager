import type { Region } from "./lottery-domain";

export type StationInfo = {
  code: string;
  name: string;
  region: Region;
  weekdays: number[];
};

// Weekday follows Date#getUTCDay(): 0 = Chủ nhật, 1 = Thứ hai, ... 6 = Thứ bảy.
export const LOTTERY_STATIONS: StationInfo[] = [
  { code: "MB", name: "Hội đồng XSKT miền Bắc", region: "Miền Bắc", weekdays: [0, 1, 2, 3, 4, 5, 6] },

  { code: "TTH", name: "Thừa Thiên Huế", region: "Miền Trung", weekdays: [0, 1] },
  { code: "PY", name: "Phú Yên", region: "Miền Trung", weekdays: [1] },
  { code: "DLK", name: "Đắk Lắk", region: "Miền Trung", weekdays: [2] },
  { code: "QNA", name: "Quảng Nam", region: "Miền Trung", weekdays: [2] },
  { code: "DNG", name: "Đà Nẵng", region: "Miền Trung", weekdays: [3, 6] },
  { code: "KH", name: "Khánh Hòa", region: "Miền Trung", weekdays: [0, 3] },
  { code: "BDI", name: "Bình Định", region: "Miền Trung", weekdays: [4] },
  { code: "QB", name: "Quảng Bình", region: "Miền Trung", weekdays: [4] },
  { code: "QT", name: "Quảng Trị", region: "Miền Trung", weekdays: [4] },
  { code: "GL", name: "Gia Lai", region: "Miền Trung", weekdays: [5] },
  { code: "NT", name: "Ninh Thuận", region: "Miền Trung", weekdays: [5] },
  { code: "QNG", name: "Quảng Ngãi", region: "Miền Trung", weekdays: [6] },
  { code: "DNO", name: "Đắk Nông", region: "Miền Trung", weekdays: [6] },
  { code: "KT", name: "Kon Tum", region: "Miền Trung", weekdays: [0] },

  { code: "HCM", name: "TP. Hồ Chí Minh", region: "Miền Nam", weekdays: [1, 6] },
  { code: "DT", name: "Đồng Tháp", region: "Miền Nam", weekdays: [1] },
  { code: "CM", name: "Cà Mau", region: "Miền Nam", weekdays: [1] },
  { code: "BTR", name: "Bến Tre", region: "Miền Nam", weekdays: [2] },
  { code: "VT", name: "Vũng Tàu", region: "Miền Nam", weekdays: [2] },
  { code: "BL", name: "Bạc Liêu", region: "Miền Nam", weekdays: [2] },
  { code: "DNA", name: "Đồng Nai", region: "Miền Nam", weekdays: [3] },
  { code: "CT", name: "Cần Thơ", region: "Miền Nam", weekdays: [3] },
  { code: "ST", name: "Sóc Trăng", region: "Miền Nam", weekdays: [3] },
  { code: "TN", name: "Tây Ninh", region: "Miền Nam", weekdays: [4] },
  { code: "AG", name: "An Giang", region: "Miền Nam", weekdays: [4] },
  { code: "BTH", name: "Bình Thuận", region: "Miền Nam", weekdays: [4] },
  { code: "VL", name: "Vĩnh Long", region: "Miền Nam", weekdays: [5] },
  { code: "BD", name: "Bình Dương", region: "Miền Nam", weekdays: [5] },
  { code: "TV", name: "Trà Vinh", region: "Miền Nam", weekdays: [5] },
  { code: "LA", name: "Long An", region: "Miền Nam", weekdays: [6] },
  { code: "BP", name: "Bình Phước", region: "Miền Nam", weekdays: [6] },
  { code: "HG", name: "Hậu Giang", region: "Miền Nam", weekdays: [6] },
  { code: "TG", name: "Tiền Giang", region: "Miền Nam", weekdays: [0] },
  { code: "KG", name: "Kiên Giang", region: "Miền Nam", weekdays: [0] },
  { code: "LD", name: "Đà Lạt", region: "Miền Nam", weekdays: [0] },
];

export function stationsForRegion(region: Region) {
  return LOTTERY_STATIONS.filter((station) => station.region === region);
}

export function stationsForDrawDate(region: Region, date: Date) {
  const weekday = date.getUTCDay();
  return stationsForRegion(region).filter((station) => station.weekdays.includes(weekday));
}

export function stationSearchKey(value: string) {
  const key = value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replaceAll("đ", "d")
    .replaceAll("Đ", "D")
    .replace(/[^a-zA-Z0-9]/g, "")
    .toLowerCase();
  if (["hcm", "tphcm", "hochiminh", "tphochiminh"].includes(key)) return "hcm";
  return key;
}

export function stationMatches(left: string, right: string) {
  return stationSearchKey(left) === stationSearchKey(right);
}

export function canonicalStationName(value: string, region: Region) {
  return stationsForRegion(region).find((station) => stationMatches(station.name, value))?.name ?? value.trim();
}
