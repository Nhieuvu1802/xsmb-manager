import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { lotteryPrisma?: PrismaClient };

export function databaseIsConfigured() {
  return Boolean(process.env.DATABASE_URL?.trim());
}

export function getPrisma() {
  if (!databaseIsConfigured()) return null;

  if (!globalForPrisma.lotteryPrisma) {
    globalForPrisma.lotteryPrisma = new PrismaClient({
      log: process.env.NODE_ENV === "development" ? ["warn", "error"] : ["error"],
    });
  }

  return globalForPrisma.lotteryPrisma;
}
