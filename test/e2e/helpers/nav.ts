import { expect, Locator, Page } from '@playwright/test'

export async function openPage(page: Page, route: string, ready: Locator) {
  const link = page.locator(`.sidebar a[href$="${route}"]`)
  if (route.startsWith('settings/') && !(await link.isVisible())) {
    await page.locator('.sidebar li.menu-system > a').filter({ hasText: 'Settings' }).click()
  }
  await link.click()
  await expect(ready).toBeVisible()
}
