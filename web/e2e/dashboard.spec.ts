import { expect, test } from "@playwright/test";

test("dashboard và màn phân tích hoạt động", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Tổng quan xác suất" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Hiểu xác suất. Giữ giới hạn." })).toBeVisible();
  const navigation = (page.viewportSize()?.width ?? 1200) < 800 ? page.locator(".bottom-nav") : page.locator(".side-nav");
  await navigation.getByRole("button", { name: /^Phân tích/ }).click();
  await expect(page.getByRole("heading", { name: "Kiểm tra bộ số" })).toBeVisible();
  await expect(page.getByText("Các kỳ quay độc lập")).toBeVisible();
});
