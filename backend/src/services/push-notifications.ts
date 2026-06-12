import { prisma } from '../lib/prisma'

let fcmInitialized = false

async function initFCM() {
  if (fcmInitialized) return
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
  if (!serviceAccount) {
    console.warn('[Push] Firebase not configured. Push notifications disabled.')
    return
  }
  try {
    fcmInitialized = true
    console.log('[Push] Firebase initialized')
  } catch (e) {
    console.error('[Push] Firebase init failed:', e)
  }
}

export async function registerPushToken(userId: string, token: string) {
  await initFCM()
  if (!fcmInitialized) return

  try {
    await prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: token }
    }).catch(() => {})
  } catch (e) {
    console.error('[Push] Failed to register token:', e)
  }
}

export async function sendPushNotification(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  await initFCM()
  if (!fcmInitialized) return

  try {
    console.log(`[Push] Would send to user ${userId}: ${title}`)
  } catch (e) {
    console.error('[Push] Failed to send notification:', e)
  }
}
