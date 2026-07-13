import { Page } from '@playwright/test'

export async function loginViaAuthelia(page: Page, baseURL: string, username: string, password: string) {
  const appHost = new URL(baseURL).host

  await page.goto(baseURL)
  await page.waitForURL((url) => url.host.startsWith('auth.'))

  await page.locator('input#username-textfield').fill(username)
  await page.locator('input#password-textfield').fill(password)
  await page.locator('button#sign-in-button').click()

  await page.waitForURL((url) => url.host === appHost)
}
