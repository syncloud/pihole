import { expect, Page } from '@playwright/test'

const username = process.env.PLAYWRIGHT_DEVICE_USER ?? 'user'
const password = process.env.PLAYWRIGHT_DEVICE_PASSWORD ?? 'Password1'

export async function loginViaAuthelia(page: Page) {
  await page.goto('/')
  await page.waitForURL((url) => url.host.startsWith('auth.'))
  await page.locator('input#username-textfield').fill(username)
  await page.locator('input#password-textfield').fill(password)
  await page.locator('button#sign-in-button').click()
  await expect(page.locator('#total_queries')).toBeVisible()
}
