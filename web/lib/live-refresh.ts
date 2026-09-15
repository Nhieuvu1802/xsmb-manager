/** Adaptive refresh interval based on Vietnam lottery draw windows (UTC+7). */
export function liveRefreshInterval(now = new Date()): number {
  const vietnamMinutes = ((now.getUTCHours() + 7) % 24) * 60 + now.getUTCMinutes();
  return vietnamMinutes >= 16 * 60 && vietnamMinutes <= 19 * 60 + 15
    ? 45_000
    : 30 * 60_000;
}
