import { expect, Page } from '@playwright/test'
import { env } from './env'

const username = env('PLAYWRIGHT_DEVICE_USER')
const password = env('PLAYWRIGHT_DEVICE_PASSWORD')

export async function loginViaAuthelia(page: Page) {
  await page.goto('/')
  await page.waitForURL((url) => url.host.startsWith('auth.'))
  await page.locator('input#username-textfield').fill(username)
  await page.locator('input#password-textfield').fill(password)
  await page.locator('button#sign-in-button').click()
  const dashboard = page.locator('#total_queries')
  const skipPasskey = page.getByTestId('passkey-skip')
  await expect(dashboard.or(skipPasskey)).toBeVisible()
  if (await skipPasskey.isVisible()) {
    await skipPasskey.click()
  }
  await expect(dashboard).toBeVisible()
}
