/**
 * Beast System 3.0 — Treasury Allocation Math
 * LUCR Principle: wellbeing → stability → profit
 */

export interface StabilityMetrics {
  system: number;      // S
  wellbeing: number;   // W
  community: number;   // C
}

export interface AllocationResult {
  development: number;
  wellbeing: number;
  community: number;
  emergency: number;
  multiplier: number;
}

export function computeTreasuryAllocation(
  revenue: number,
  metrics: StabilityMetrics
): AllocationResult {

  const { system, wellbeing, community } = metrics;

  // Treasury Stability Score
  const TSS = (system + wellbeing + community) / 3;

  // Emergency allocation adjustment
  let emergency = 0.10 + (1 - TSS);
  emergency = Math.min(emergency, 0.25); // cap at 25%

  // Base allocations
  let devBase = 0.40;
  let wellBase = 0.30;
  let comBase = 0.20;

  // Scale remaining allocations
  const remaining = 1 - emergency;

  const development = revenue * devBase * remaining;
  const wellbeingAlloc = revenue * wellBase * remaining;
  const communityAlloc = revenue * comBase * remaining;
  const emergencyAlloc = revenue * emergency;

  // LUCR Strength Index
  const LSI = (system + wellbeing + community) / 3;

  // Treasury Growth Multiplier
  const multiplier = Math.log(LSI + 1);

  return {
    development: development * multiplier,
    wellbeing: wellbeingAlloc * multiplier,
    community: communityAlloc * multiplier,
    emergency: emergencyAlloc * multiplier,
    multiplier
  };
}
