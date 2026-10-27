import { expect, Locator, Page } from '@playwright/test'

export async function openPage(page: Page, route: string, ready: Locator) {
  const link = page.locator(`.sidebar a[href$="${route}"]`)
  if (!(await link.isVisible())) {
    await page.locator(`.sidebar li.treeview:has(a[href$="${route}"]) > a`).click()
  }
  await link.click()
  await expect(ready).toBeVisible()
}
