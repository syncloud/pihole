import { Page } from '@playwright/test'

export async function openPage(page: Page, route: string) {
  if (route.startsWith('settings/')) {
    const sub = page.locator(`.sidebar a[href$="${route}"]`)
    if (!(await sub.isVisible())) {
      await page.locator('.sidebar li.menu-system > a').click()
    }
  }
  await page.locator(`.sidebar a[href$="${route}"]`).click()
  await page.waitForLoadState('networkidle')
}
