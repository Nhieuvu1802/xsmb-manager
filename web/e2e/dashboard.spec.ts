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

test("đổi miền và lọc đài miền Nam", async ({ page }) => {
  await page.goto("/");
  const filters = (page.viewportSize()?.width ?? 1200) < 800 ? page.locator(".mobile-filters") : page.locator(".desktop-filters");
  await filters.locator("select").nth(0).selectOption("Miền Nam");
  await expect(filters.locator("select").nth(1)).toContainText("TP. Hồ Chí Minh");
  await filters.locator("select").nth(1).selectOption("TP. Hồ Chí Minh");
  await expect(page.locator(".draw-panel").getByRole("heading", { name: "TP. Hồ Chí Minh" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Hai đài trên cùng một bảng giải" })).toBeVisible();
  await expect(page.locator(".dual-station-table thead strong")).toHaveCount(2);
});

test("quay thử dùng số ngẫu nhiên và hiện cảnh báo thống kê", async ({ page }) => {
  await page.goto("/");
  const navigation = (page.viewportSize()?.width ?? 1200) < 800 ? page.locator(".bottom-nav") : page.locator(".side-nav");
  await navigation.getByRole("button", { name: /^Quay thử/ }).click();
  await expect(page.getByRole("heading", { name: "Quay thử & xếp hạng lịch sử" })).toBeVisible();
  await expect(page.getByText("Không phải dự đoán")).toBeVisible();
  await page.getByRole("button", { name: "Quay thử một lượt" }).click();
  await expect(page.locator(".spin-history b").first()).toBeVisible({ timeout: 3000 });
});
